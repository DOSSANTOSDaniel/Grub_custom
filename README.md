# Grub_custom
Testé sur Ubuntu 20.04, Fedora 35 et Arch linux 2021.

# Ce script permet d'automatiser certaines tâches de personnalisation de Grub.

## Ce script attend en entrée certains objets :

a. un dossier de thème valide, exemple :
```
#    dark-matter
#    ├── background.png
#    ...
#    ├── icons
#    │   ├── archlinux.png
#    ...
#    ├── JetBrainsMono_Bold_15.pf2
#    ...
#    └── theme.txt
```
b. Une image pour le background de grub si on veut la personnalisée (Optionnel).

## Tâches principales du script : 

 1. Installer de nouveaux thèmes Grub.
 2. Possibilité de changer l'image de background du thème installé.
 3. Activer ou désactiver les thèmes installés.
 4. Désinstaller un thème.
 5. Remètre la configuration de grub par défaut.  
                                                   
## Autres tâches exécutées par le script :

 1. Sauvegarde de la configuration de Grub : /etc/default/grub.save
 
 2. Sauvegarde de la précédente image de background de Grub dans :
    /home/user/Images/background_grub_backup/
 
 3. Crée un fichier de métadonnées pour détecter si c'est une première installation :
    /boot/grub/themes/.script_grub_custom.txt

 4. Par rapport à la fonction de modification des images de background,
    le script permet de comparer la résolution du système par rapport à la résolution
    d'une image de background dans le but de choisir :
     1. Changer la résolution de l'image si elle est supérieure à la résolution du système.
     2. Avertir l'utilisateur si l'image a une résolution inférieure à celle du système,
        dans ce cas de figure l'image garde sa résolution par défaut.

 5. Adapte les images :
     1. format JPG/JPEG : 8-bit (256 color), non indexée, sRGB.
     2. format PNG et TAG : non indexée, sRGB.

 6. Installation de dépendances :
    1. Pour Ubuntu 20.4 : "imagemagick" "x11-xserver-utils" "libfile-mimeinfo-perl".
    2. Pour Fedora 35 : "ImageMagick" "xrandr" "perl-File-MimeInfo".
    3. Pour Arch : "glibc" "libmagick" "imagemagick" "xorg-xrandr" "perl-file-mimeinfo".

 7. Détecte le mode de boot UEFI ou LEGACY.
                                                                                                     
## Usage:
1. Télécharger un thème pour Grub : https://www.gnome-look.org/browse?cat=109
2. Décompresser le thème.
3. Télécharger éventuellement une image de fond pour adapter à un thème (optionnel).
4. Lancer le script et laisser-vous guider : ./grub_theme_conf.sh
