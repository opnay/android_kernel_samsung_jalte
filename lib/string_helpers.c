/*
 * Helpers for formatting and printing strings
 *
 * Copyright 31 August 2008 James Bottomley
 * Copyright (C) 2013, Intel Corporation
 */
#include <linux/bug.h>
#include <linux/kernel.h>
#include <linux/math64.h>
#include <linux/export.h>
#include <linux/ctype.h>
#include <linux/string_helpers.h>

/**
 * string_get_size - get the size in the specified units
 * @size:	The size to be converted in blocks
 * @blk_size:	Size of the block (use 1 for size in bytes)
 * @units:	units to use (powers of 1000 or 1024)
 * @buf:	buffer to format to
 * @len:	length of buffer
 *
 * This function returns a string formatted to 3 significant figures
 * giving the size in the required units.  @buf should have room for
 * at least 9 bytes and will always be zero terminated.
 *
 */
void string_get_size(u64 size, u64 blk_size, const enum string_size_units units,
		     char *buf, int len)
{
	static const char *const units_10[] = {
		"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
	};
	static const char *const units_2[] = {
		"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"
	};
	static const char *const *const units_str[] = {
		[STRING_UNITS_10] = units_10,
		[STRING_UNITS_2] = units_2,
	};
	static const unsigned int divisor[] = {
		[STRING_UNITS_10] = 1000,
		[STRING_UNITS_2] = 1024,
	};
	int i, j;
	u32 remainder = 0, sf_cap, exp;
	char tmp[8];
	const char *unit;

	tmp[0] = '\0';
	i = 0;
	if (!size)
		goto out;

	while (blk_size >= divisor[units]) {
		remainder = do_div(blk_size, divisor[units]);
		i++;
	}

	exp = divisor[units] / (u32)blk_size;
	if (size >= exp) {
		remainder = do_div(size, divisor[units]);
		remainder *= blk_size;
		i++;
	} else {
		remainder *= size;
	}

	size *= blk_size;
	size += remainder / divisor[units];
	remainder %= divisor[units];

	while (size >= divisor[units]) {
		remainder = do_div(size, divisor[units]);
		i++;
	}

	sf_cap = size;
	for (j = 0; sf_cap*10 < 1000; j++)
		sf_cap *= 10;

	if (j) {
		remainder *= 1000;
		remainder /= divisor[units];
		snprintf(tmp, sizeof(tmp), ".%03u", remainder);
		tmp[j+1] = '\0';
	}

 out:
	if (i >= ARRAY_SIZE(units_2))
		unit = "UNK";
	else
		unit = units_str[units][i];

	snprintf(buf, len, "%u%s %s", (u32)size,
		 tmp, unit);
}
EXPORT_SYMBOL(string_get_size);

static bool unescape_space(char **src, char **dst)
{
	char *p = *dst, *q = *src;

	switch (*q) {
	case 'n':
		*p = '\n';
		break;
	case 'r':
		*p = '\r';
		break;
	case 't':
		*p = '\t';
		break;
	case 'v':
		*p = '\v';
		break;
	case 'f':
		*p = '\f';
		break;
	default:
		return false;
	}
	*dst += 1;
	*src += 1;
	return true;
}

static bool unescape_octal(char **src, char **dst)
{
	char *p = *dst, *q = *src;
	u8 num;

	if (isodigit(*q) == 0)
		return false;

	num = (*q++) & 7;
	while (num < 32 && isodigit(*q) && (q - *src < 3)) {
		num <<= 3;
		num += (*q++) & 7;
	}
	*p = num;
	*dst += 1;
	*src = q;
	return true;
}

static bool unescape_hex(char **src, char **dst)
{
	char *p = *dst, *q = *src;
	int digit;
	u8 num;

	if (*q++ != 'x')
		return false;

	num = digit = hex_to_bin(*q++);
	if (digit < 0)
		return false;

	digit = hex_to_bin(*q);
	if (digit >= 0) {
		q++;
		num = (num << 4) | digit;
	}
	*p = num;
	*dst += 1;
	*src = q;
	return true;
}

static bool unescape_special(char **src, char **dst)
{
	char *p = *dst, *q = *src;

	switch (*q) {
	case '\"':
		*p = '\"';
		break;
	case '\\':
		*p = '\\';
		break;
	case 'a':
		*p = '\a';
		break;
	case 'e':
		*p = '\e';
		break;
	default:
		return false;
	}
	*dst += 1;
	*src += 1;
	return true;
}

/**
 * string_unescape - unquote characters in the given string
 * @src:	source buffer (escaped)
 * @dst:	destination buffer (unescaped)
 * @size:	size of the destination buffer (0 to unlimit)
 * @flags:	combination of the flags (bitwise OR):
 *	%UNESCAPE_SPACE:
 *		'\f' - form feed
 *		'\n' - new line
 *		'\r' - carriage return
 *		'\t' - horizontal tab
 *		'\v' - vertical tab
 *	%UNESCAPE_OCTAL:
 *		'\NNN' - byte with octal value NNN (1 to 3 digits)
 *	%UNESCAPE_HEX:
 *		'\xHH' - byte with hexadecimal value HH (1 to 2 digits)
 *	%UNESCAPE_SPECIAL:
 *		'\"' - double quote
 *		'\\' - backslash
 *		'\a' - alert (BEL)
 *		'\e' - escape
 *	%UNESCAPE_ANY:
 *		all previous together
 *
 * Description:
 * The function unquotes characters in the given string.
 *
 * Because the size of the output will be the same as or less than the size of
 * the input, the transformation may be performed in place.
 *
 * Caller must provide valid source and destination pointers. Be aware that
 * destination buffer will always be NULL-terminated. Source string must be
 * NULL-terminated as well.
 *
 * Return:
 * The amount of the characters processed to the destination buffer excluding
 * trailing '\0' is returned.
 */
int string_unescape(char *src, char *dst, size_t size, unsigned int flags)
{
	char *out = dst;

	while (*src && --size) {
		if (src[0] == '\\' && src[1] != '\0' && size > 1) {
			src++;
			size--;

			if (flags & UNESCAPE_SPACE &&
					unescape_space(&src, &out))
				continue;

			if (flags & UNESCAPE_OCTAL &&
					unescape_octal(&src, &out))
				continue;

			if (flags & UNESCAPE_HEX &&
					unescape_hex(&src, &out))
				continue;

			if (flags & UNESCAPE_SPECIAL &&
					unescape_special(&src, &out))
				continue;

			*out++ = '\\';
		}
		*out++ = *src++;
	}
	*out = '\0';

	return out - dst;
}
EXPORT_SYMBOL(string_unescape);
