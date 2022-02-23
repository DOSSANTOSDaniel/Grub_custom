#!/bin/bash
#-*- coding: UTF8 -*-

#--------------------------------------------------#
# Script_Name: grub_theme_conf.sh	                               
#                                                   
# Author:  'dossantosjdf@gmail.com'                 
# Date:     23/02/2022 04:29:15                                             
# Version:  1.0                                      
# Bash_Version: 5.0.17(1)-release                                     
#--------------------------------------------------#
# Description: 
#
# Testé sur Ubuntu 20.04, Fedora 35 et Arch linux 2021.
#
# Ce script permet d'automatiser certaines tâches de personnalisation de Grub.
#
# Ce script attend en entrée certains objets :
#
# a. un dossier de thème valide, exemple :
#
#    dark-matter
#    ├── background.png
#    ...
#    ├── icons
#    │   ├── archlinux.png
#    ...
#    ├── JetBrainsMono_Bold_15.pf2
#    ...
#    └── theme.txt
#
# b. Une image pour le background de grub si on veut la personnalisée (Optionnel).
#
# Tâches principales du script : 
#
# 1. Installer de nouveaux thèmes Grub.
# 2. Possibilité de changer l'image de background du thème installé.
# 3. Activer ou désactiver les thèmes installés.
# 4. Désinstaller un thème.
# 5. Remètre la configuration de grub par défaut.  
#                                                   
# Autres tâches exécutées par le script :
#
# 1. Sauvegarde de la configuration de Grub : /etc/default/grub.save
# 
# 2. Sauvegarde de la précédente image de background de Grub dans :
#    /home/<user>/Images/background_grub_backup/
# 
# 3. Crée un fichier de métadonnées pour détecter si c'est une première installation :
#    /boot/grub/themes/.script_grub_custom.txt
#
# 4. Par rapport à la fonction de modification des images de background,
#    le script permet de comparer la résolution du système par rapport à la résolution
#    d'une image de background dans le but de choisir :
#     1. Changer la résolution de l'image si elle est supérieure à la résolution du système.
#     2. Avertir l'utilisateur si l'image a une résolution inférieure à celle du système,
#        dans ce cas de figure l'image garde sa résolution par défaut.
#
# 5. Adapte les images :
#     1. format JPG/JPEG : 8-bit (256 color), non indexée, sRGB.
#     2. format PNG et TAG : non indexée, sRGB.
#
# 6. Installation de dépendances :
#    1. Pour Ubuntu 20.4 : "imagemagick","x11-xserver-utils","libfile-mimeinfo-perl".
#    2. Pour Fedora 35 : "ImageMagick","xrandr","perl-File-MimeInfo".
#    3. Pour Arch : "glibc" "libmagick" "imagemagick" "xorg-xrandr" "perl-file-mimeinfo".
#
# 7. Détecte le mode de boot UEFI ou LEGACY.
#                                                                                                     
# Usage:
#
# 1. Télécharger un thème pour Grub : https://www.gnome-look.org/browse?cat=109
# 2. Décompresser le thème.
# 3. Télécharger éventuellement une image de fond pour adapter à un thème (optionnel).
# 4. Lancer le script et laisser-vous guider : ./grub_theme_conf.sh
#                                                   
# Limits:                                          
#                                                   
# Licence:                                          
#--------------------------------------------------#

############################## Functions #############################################
######################################################################################

modify_grub_config() {
  echo "Modification du fichier de configuration de Grub"
  # Check themes directory
  if [[ -d /boot/${grub_dir}/themes ]]
  then
    echo "Dossier themes présent"
  else
    echo "Création du dossier themes "
    mkdir -p /boot/"${grub_dir}"/themes
  fi
  if [[ ! -f /boot/${grub_dir}/themes/.script_grub_custom.txt ]]
  then
    #Delete
    local -a tab_del=("GRUB_TIMEOUT"
    "GRUB_DEFAULT"
    "GRUB_TERMINAL_OUTPUT"
    "GRUB_ENABLE_BLSCFG"
    "GRUB_TIMEOUT_STYLE"
    "GRUB_BACKGROUND"
    "GRUB_GFXMODE"
    "GRUB_HIDDEN_TIMEOUT"
    "GRUB_HIDDEN_TIMEOUT_QUIET"
    "GRUB_GFXPAYLOAD"
    "GRUB_GFXPAYLOAD_LINUX"
    "GRUB_THEME")
     
    for item_del in "${tab_del[@]}"
    do
      grep "^${item_del}=.*$" /etc/default/grub && sed -i "/^${item_del}=.*$/d" /etc/default/grub
    done
    
    #Append
    sed  -i '1i #Fichier modifié par le script Grub custom' /etc/default/grub
    sed  -i '2i #Une sauvegarde de ce fichier : /etc/default/grub.save' /etc/default/grub
    
    local -a tab_add=("GRUB_TIMEOUT=10"
    "GRUB_DEFAULT=0"
    "GRUB_TERMINAL_OUTPUT='gfxterm'"
    "GRUB_TIMEOUT_STYLE='menu'"
    "GRUB_GFXMODE='auto'")
    
    for item_add in "${tab_add[@]}"
    do
      echo "$item_add" >> /etc/default/grub
    done
    
    # make initial file
    echo "Installation initiale"
    sleep 3
    local date_0
    date_0="$(date +"%Y-%m-%d %H:%M")"
    echo "Initial install at : $date_0" > /boot/"${grub_dir}"/themes/.script_grub_custom.txt

    { 
      echo "Infos"
      echo "------"
      echo "Boot mode : $boot_mode"
      echo "Linux distribuation : $linux_dist $linux_dist_ver"
      echo "Paths" 
      echo "------"
      echo "Backup for grub configuration : /etc/default/grub.save"
      echo "Themes directory : /boot/${grub_dir}/themes"
      echo "Grub configuration : /etc/default/grub"
    } >> /boot/"${grub_dir}"/themes/.script_grub_custom.txt
  else
    echo "Installation non initiale"
    sleep 3
  fi
}


search_images() {
  local IFS=$'\n'
  local PS3='Votre choix: '
  
  full_path='/home'
  local count=0
  
  clear
  
  while :
  do
    clear
    echo -e "\n[-- Menu fichiers --->\n"
  
    mapfile -t files < <(ls -B ${full_path})
  
    select ITEM in "${files[@]}" 'Retour' 'Quitter'
    do
      if [[ "${ITEM}" == "Quitter" ]]
      then
        exit 1
      elif [[ "${ITEM}" == "Retour" ]]
      then
        if [[ ${count} -gt 0 ]]
        then
          full_path=$(dirname "$full_path")
          set +e
          (( count-- ))
          set -e
        fi
        break
      else
        full_path="${full_path}/${ITEM}"
        set +e
        (( count++ ))
        set -e
        break
      fi
    done
  
    # check if valid image
    
    if [[ -f "$full_path" ]]
    then
      local ext
      ext="$(mimetype "$full_path")"
      
      if [[ "$ext" =~ image/* ]]
      then
	clear
        echo "Image valide"
        new_grub_img="$full_path"
        
        # show resolution
        screen_size="$(xrandr | grep -F '*' | awk '{print $1}')"
        local img_size
        img_size="$(identify "$new_grub_img" | cut -d ' ' -f3)"    
        local screen_size_w
        screen_size_w="$(xrandr | grep -F '*' | awk '{print $1}' | cut -d 'x' -f1)"
        local screen_size_h
        screen_size_h="$(xrandr | grep -F '*' | awk '{print $1}' | cut -d 'x' -f2)"
        local img_size_w     
        img_size_w="$(echo "$img_size" | cut -d 'x' -f1)"
        local img_size_h
        img_size_h="$(echo "$img_size" | cut -d 'x' -f2)"
        
        if [[ "$img_size_w" -lt "$screen_size_w" || "$img_size_h" -lt "$screen_size_h" ]]
        then
          echo "L'image selectionnée a une résolution inférieur à celle du système !"
          echo "Image : $(basename "$new_grub_img")"
          echo "La résolution de votre image : $img_size"
          echo "La résolution sur votre système : $screen_size"     
       
          read -p "Voulez vous vraiment utiliser cette image ? [o/n] : " resp_use_img
          case "$resp_use_img" in
          [o][O][OUI]|[oui]) 
            screen_size="$img_size"
            break
          ;;
          *)
            full_path=$(dirname "$full_path")
            set +e
            (( count-- ))
            set -e  
          ;;
          esac          
        fi
        break        
      fi
    fi
  done
  # new_grub_img
  # screen_size
}


add_image() {
  # Backup old background image
  [[ -d /home/"${username}"/Images/background_grub_backup ]] || (mkdir -p /home/"${username}"/Images/background_grub_backup && chown -R "${username}":"${username}" /home/"${username}"/Images/background_grub_backup)
  
  # Current theme grub
  current_theme_file="$(grep "^GRUB_THEME=.*$" /etc/default/grub | cut -d '"' -f2)"
  current_theme_dir="$(dirname "$current_theme_file")"
  echo "Backup de l'ancienne image de grub : /home/"${username}"/Images/background_grub_backup/"${old_img_grub}""
  if cp "${current_theme_dir}"/background.png /home/"${username}"/Images/background_grub_backup/"${old_img_grub}"
  then
    chown "${username}":"${username}" /home/"${username}"/Images/background_grub_backup/"${old_img_grub}"
    #format JPG/JPEG : 8-bit (256 color), non indexée, RGB.
    #format PNG and TAG : non indexée, RGB.
    echo "Convertion de l'image $new_grub_img et sauvegarde"
    convert "$new_grub_img" -depth 8 -resize "${screen_size}"+0+0 -colorspace sRGB "${current_theme_dir}"/background.png
  else
    echo "Erreur de la copie de l'image"
    exit 0
  fi
}


search_themes() {
  local IFS=$'\n'
  local PS3='Votre choix: '
  
  full_path='/home'
  local count=0
  
  clear
  
  while :
  do
    clear
    echo -e "\n[-- Menu fichiers --->\n"
  
    mapfile -t files < <(ls ${full_path})
  
    select ITEM in "${files[@]}" 'Retour' 'Quitter'
    do
      if [[ "${ITEM}" == "Quitter" ]]
      then
        exit 1
      elif [[ "${ITEM}" == "Retour" ]]
      then
        if [[ ${count} -gt 0 ]]
        then
          full_path=$(dirname "$full_path")
          set +e
          (( count-- ))
          set -e
        fi
        break
      else
        full_path="${full_path}/${ITEM}"
        set +e
        (( count++ ))
        set -e
        break
      fi
    done
  
    if [[ -d "$full_path" && -f "${full_path}/theme.txt" ]]
    then
      break
    fi
  done

  file_selected_theme="$full_path"
}


add_new_theme() {  
  local basename_theme
  basename_theme="$(basename "$file_selected_theme")"

  if [[ -d /boot/${grub_dir}/themes/${basename_theme} ]]
  then
    echo "Thème déja installé"
    exit 0
  else
    echo "Installation du thème !"
    cp -rp "$file_selected_theme" /boot/"${grub_dir}"/themes
    #Modify grub
    grep "^GRUB_THEME=.*$" /etc/default/grub && sed -i "/^GRUB_THEME=.*$/d" /etc/default/grub
    echo "GRUB_THEME=\"/boot/${grub_dir}/themes/${basename_theme}/theme.txt\"" >> /etc/default/grub
    #Update grub
    grub_up
  fi
}


show_installed_themes() {
  ## Menu installed themes
  local PS3="Votre choix : "
  local installed_themes="/boot/${grub_dir}/themes"
  
  mapfile -t files < <(ls -B "$installed_themes")
  
  clear
  
  echo -e "\n -- Menu thèmes -- "
  select ITEM in "${files[@]}" 'Quitter'
  do
    if [[ $ITEM == 'Quitter' ]]
    then
      exit 0
    else
      selected_theme="${ITEM}"
    fi
  break 
  done
  #selected_theme
}


delete_theme() {
  if grep -F "GRUB_THEME=\"/boot/${grub_dir}/themes/${selected_theme}/theme.txt\"" /etc/default/grub;
  then
    echo "Thème en cours d'utilisation par le système"
    
    read -p "Voulez vous vraiment suprimer le thème actuel ? [o/n] : " resp_del_theme
    case "$resp_del_theme" in
    [o][O][OUI]|[oui]) 
      echo "Supression du thème $selected_theme"
      sed -i "/^GRUB_THEME=.*$/d" /etc/default/grub
      rm -rf /boot/"${grub_dir}"/themes/"${selected_theme}"
      grub_up
      ;;
    *)
      exit 0
      ;;
    esac
  else
    echo "Supression du thème $selected_theme"
    rm -rf /boot/"${grub_dir}"/themes/"${selected_theme}"
  fi
}


switch_theme() {
  if grep "GRUB_THEME=\"/boot/${grub_dir}/themes/${selected_theme}\"" /etc/default/grub
  then
    echo "Thème déjà activé comme thème de grub par défaut"
    exit 0
  else
    echo "Activation du thème !"
    #Modify grub
    grep "^GRUB_THEME=.*$" /etc/default/grub && sed -i "/^GRUB_THEME=.*$/d" /etc/default/grub
    echo "GRUB_THEME=\"/boot/${grub_dir}/themes/${selected_theme}/theme.txt\"" >> /etc/default/grub
    grub_up
  fi
}


restore_grub_config() {
  if [[ -f "/etc/default/grub.save" ]]
  then
    rm -rf /etc/default/grub && mv /etc/default/grub.save /etc/default/grub
    #rm -rf /boot/"${grub_dir}"/themes
    grub_up
  else
    echo "Sauvegarde de grub non existante"
    exit 0
  fi
}


exit_script() {
  echo '#--------------------------------------->' 
  echo -e "\n Fin du script ! \n"
}

############################ Variables ###############################################
######################################################################################

readonly old_img_grub="back_$(date +"%Y_%m_%d-%H%M%S").png"
readonly username="$(grep ":1000:1000:" /etc/passwd | awk -F':' '{print $1}')"
boot_mode="legacy"

################################# Main ###############################################
######################################################################################
trap exit_script EXIT

clear

cat << "EOF"

  ____            _                      _                  
 / ___|_ __ _   _| |__     ___ _   _ ___| |_ ___  _ __ ___  
| |  _| '__| | | | '_ \   / __| | | / __| __/ _ \| '_ ` _ \ 
| |_| | |  | |_| | |_) | | (__| |_| \__ \ || (_) | | | | | |
 \____|_|   \__,_|_.__/   \___|\__,_|___/\__\___/|_| |_| |_|
                                                                  

EOF

# Check user and force root login
if [ "$(id -u)" -ne 0 ]
then
  echo 'Le script doit être lancé en tant que root !!!'
  if command -v sudo > /dev/null
  then
    exec sudo ./"${0}"
  else
    exec su -c "$0" root
  fi
fi

# Check boot mode
if [[ -d /boot/efi && -d /sys/firmware/efi ]]
then
  readonly boot_mode="uefi"
fi

# Check path grub
if [[ -d /boot/grub ]]
then
  readonly grub_dir="grub"
elif [[ -d /boot/grub2 ]]
then
  readonly grub_dir="grub2"
else
  echo "Version incompabible de Grub ou Grub non installé"
  exit 0
fi

# Check linux distribution
if [[ "$OSTYPE" =~ linux* ]]
then
  if [[ -f /etc/os-release ]]
  then
    readonly linux_dist="$(grep "^ID=" /etc/os-release | cut -d '=' -f2)"
    readonly linux_dist_ver="$(grep "^VERSION_ID=" /etc/os-release | cut -d '=' -f2)"
  fi
else
  echo "$OSTYPE non compatible avec ce script"
  exit 0
fi

# Check package manager and install deps
case $linux_dist in
debian|ubuntu)
  grub_up() {
    update-grub
  }
  if dpkg -s "apt" > /dev/null || dpkg -s "apt-get" > /dev/null
  then
    apt-get update -q  
    dpkg -s "imagemagick" > /dev/null || apt-get install imagemagick -qy
    dpkg -s "x11-xserver-utils" > /dev/null || apt-get install x11-xserver-utils -qy
    dpkg -s "libfile-mimeinfo-perl" > /dev/null || apt-get install libfile-mimeinfo-perl -qy
  else
    echo 'Gestionnaire de paquets non prit en charge'
    exit 0
  fi
  ;;
centos|fedora|almalinux)
  grub2-editenv - unset menu_auto_hide		    
  if rpm -qi "dnf" > /dev/null
  then
    dnf check-update --refresh -y  
    rpm -qi "ImageMagick" > /dev/null || dnf install ImageMagick -qy
    rpm -qi "xrandr" > /dev/null || dnf install xrandr -qy
    rpm -qi "perl-File-MimeInfo" > /dev/null || dnf install perl-File-MimeInfo -qy
  else
    echo 'INFO : Gestionnaire de paquets non prit en charge'
    exit 0
  fi
  if [[ "$boot_mode" = "uefi" ]]
  then 
    grub_up() {
      "${grub_dir}"-mkconfig -o /boot/efi/EFI/"${linux_dist}"/grub.cfg
    }
  else
    grub_up() {
      "${grub_dir}"-mkconfig -o /boot/grub2/grub.cfg
    }
  fi
  ;;
arch) 
  grub_up() {
    "${grub_dir}"-mkconfig -o /boot/grub/grub.cfg
  }
  pacman -Syyq 
  command -v "convert" || pacman -S glibc libmagick imagemagick --noconfirm
  command -v "xrandr" || pacman -S xorg-xrandr --noconfirm
  command -v "mimetype" || pacman -S perl-file-mimeinfo --noconfirm
  ;;
*)
  echo "Gestionnaire de paquets non prit en charge"
  exit 0
  ;;  
esac

if [ ! -f /etc/default/grub.save ]
then
	  cp -an /etc/default/grub /etc/default/grub.save
fi

clear

PS3="Votre choix : "
options=("Installer un nouveau thème" "Changer l'image de fond" "Basculer sur un autre thème" "Désinstaller un thème" "Réstaurer la configuration par défaut" "quitter[q/Q]")

echo -e "\n ------------ Menu ------------ "
select ITEM in "${options[@]}"
do
  case ${REPLY} in
    1) echo -e "\n Installation d'un nouveau thème !"
      modify_grub_config
      search_themes
      add_new_theme
      break;;
    2) echo -e "\n Changement du fond d'écran de grub !"
    	search_images
    	add_image
      break;;
    3) echo -e "\n Changement du thème de grub !"
      show_installed_themes
    	switch_theme
      break;;
    4) echo -e "\n Désinstallation d'un thème !"
      show_installed_themes
    	delete_theme
      break;;
    5) echo -e "\n Réstaurer la configuration par defaut de grub !"
    	restore_grub_config
      break;;            
    6|Q|q) exit;;
    *) echo "Choix $REPLY incorrect !";;
  esac
done
