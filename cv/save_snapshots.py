"""
Almacena una serie de snapshots con la camara activa actual como snapshot_<width>_<height>_<nnn>.jpg

Arguments:
    --f <output folder>     por defecto: folder por defecto
    --n <file name>         por defecto: imagen
    --w <width px>          por defecto: ninguno
    --h <height px>         por defecto: ninguno

Buttons:
    q           - salir(quit)
    space bar   - almacena el snapshot
    
Ejecute este archivo en python3 
  
"""

import cv2
import time
import sys
import argparse
import os
from pathlib import Path

__author__ = "Jose Cuartas, Basado en el desarrollo de Tiziano Fiorenzani"
__date__ = "20/12/2020"


def save_snaps(width=0, height=0, name="imagen", folder=".", raspi=False):

    dest_directory = folder
    if raspi:
    #Ejecuta comando externo para habilitar la camara en Raspberry
        os.system('sudo modprobe bcm2835-v4l2')
    #Empieza captura de video
    cap = cv2.VideoCapture(0)
    if width > 0 and height > 0:
        print("Parámetros personalizados de ancho(Width) y alto(Height)")
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    #Se crea folder donde se almacena los snapshot(imagenes estantáneas) del video
    try:
        if not os.path.exists(dest_directory):        
            # Parent Directory path
            parent_dir = os.getcwd() 
            # Path
            path = os.path.join(parent_dir, dest_directory)
            Path(path).mkdir(exist_ok=True)
 
            # ----------- CREA LA CARPETA -----------------
	    
            dest_directory = os.path.dirname(path)
            
            try:
                os.stat(dest_directory)
            except:
                os.mkdir(dest_directory)               
	   
    except:
        pass

    nSnap   = 0
    w       = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
    h       = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

    fileName    = "%s/%s_%d_%d_" %(folder, name, w, h)
    # Captura imagenes del video(fotograma) es decir, realiza un snapshot y se almacena  cada que se presiona la tecla spacebar(barra espaciadora).
    # Termina procedimiento cuando  se presiona la tecla q(quit o salir)
    while True:
        ret, frame = cap.read()
	# Despliega la imagen en una ventana
        cv2.imshow('camera', frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        if key == ord(' '):
            print("Saving image ", nSnap)
	# Graba la imagen
            cv2.imwrite("%s%d.jpg"%(fileName, nSnap), frame)
            nSnap += 1

    cap.release()
    cv2.destroyAllWindows()




def main():
    # ---- VALORES POR DEFECTO ---
    SAVE_FOLDER = "./imagenes"
    FILE_NAME = "imagen"
    FRAME_WIDTH = 0
    FRAME_HEIGHT = 0

    # ----------- PARÁMETROS DE ENTRADA -----------------
    parser = argparse.ArgumentParser(
        description="Almaceno los snapshot de la camera. \n q para salir \n spacebar para gravar el snapshot")
    parser.add_argument("--folder", default=SAVE_FOLDER, help="Ubicación donde se crea la carpeta (por defecto: ubicación actual)")
    parser.add_argument("--name", default=FILE_NAME, help="Nombre del archivo imagen (por defecto: imagenCap)")
    parser.add_argument("--dwidth", default=FRAME_WIDTH, type=int, help="<width> px (por defecto la entregada por la cámara)")
    parser.add_argument("--dheight", default=FRAME_HEIGHT, type=int, help="<height> px (por defecto la entregada por la cámara)")
    parser.add_argument("--raspi", default=False, type=bool, help="<bool> True(verdad) si esta usando una Raspberry Pi")
    args = parser.parse_args()

    SAVE_FOLDER = args.folder
    FILE_NAME = args.name
    FRAME_WIDTH = args.dwidth
    FRAME_HEIGHT = args.dheight


    save_snaps(width=args.dwidth, height=args.dheight, name=args.name, folder=args.folder, raspi=args.raspi)

    print("Imagenes guardadas")

if __name__ == "__main__":
    main()



