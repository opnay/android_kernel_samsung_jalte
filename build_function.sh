function Error() {
	echo -e "\e[01m\e[31m$* \e[00m"
}

function ShowInfo() {
	echo -e "\e[32m\e[01m$1 \e[00m$2"
}

function ShowNoty() {
	echo -e "\e[36m\e[01m$*\e[00m"
}
