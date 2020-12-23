#!/usr/bin/env python

"""
From https://opencv-python-tutroals.readthedocs.org/en/latest/py_tutorials/py_calib3d/py_calibration/py_calibration.html#calibration

Calling:
cameracalib.py  <folder> <image type> <num rows> <num cols> <cell dimension>

like cameracalib.py folder_name png

--h for help
"""
__author__ = "Jose Cuartas, Basado en el desarrollo de Tiziano Fiorenzani"
__date__ = "20/12/2020"

import numpy as np
import cv2
import glob
import sys
import argparse

#---------------------- CONFIGURAR PARAMETROS
nRows = 7
nCols = 10
dimension = 25 #- mm

workingFolder   = "./imagenes"
imageType       = 'jpg'
#------------------------------------------

# termination criteria
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# prepare object points, like (0,0,0), (1,0,0), (2,0,0) ....,(6,5,0)
objp = np.zeros((nRows*nCols,3), np.float32)
objp[:,:2] = np.mgrid[0:nCols,0:nRows].T.reshape(-1,2)
objp *= dimension

print("se crea los puntos origen note la escala que es 1 en este caso aca se multiplica por el tamanio del rectangulo en milimetros, metros, centimetros o bananos")
print(objp)

# Arrays to store object points and image points from all the images.
objpoints = [] # 3d point in real world space
imgpoints = [] # 2d points in image plane.

if len(sys.argv) < 6:
        print("\n No se porporcional suficientes argumentos de entrada, se utilizan los valores por defecto.\n\n" \
              " type -h for help")
else:
    workingFolder   = sys.argv[1]
    imageType       = sys.argv[2]
    nRows           = int(sys.argv[3])
    nCols           = int(sys.argv[4])
    dimension       = float(sys.argv[5])

if '-h' in sys.argv or '--h' in sys.argv:
    print("\n CALIBRAR IMAGEN DADA PROPORCIOANDO UN CONJUNTO DE IMAGENES")
    print(" Digita: python cameracalib.py <folder> <image type> <num rows (9)> <num cols (6)> <cell dimension (25)>")
    print("\n El  script buscara todas las imagenes en la ruta del foderl especificada y describira el patron encontrado." \
          " El usuario puede omitir la imagen presionando ESC o aceptar la iagen presionando RETURN. " \
          " At the end the end the following files are created:" \
          "  - cameraDistortion.txt" \
          "  - cameraMatrix.txt \n\n")

    sys.exit()

# Find the images files
filename    = workingFolder + "/*." + imageType
images      = glob.glob(filename)

print(len(images))
if len(images) < 9:
    print("No se encontraron suficentes imagenes:se debe proporcionar al menos 9 !!!")
    sys.exit()



else:
    nPatternFound = 0
    imgNotGood = images[1]

    for fname in images:
        if 'calibresult' in fname: continue
        #-- Lee el archivo y lo convierte en escala de grises
        img     = cv2.imread(fname)
        gray    = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)

        print("Leyendo imagen ", fname)

        # Busca las esquinas en la cuadricula de ajedrez the chess board corners
        ret, corners = cv2.findChessboardCorners(gray, (nCols,nRows),None)

        # Si la encuentra, adiciona object points, image points (after refining them)
        if ret == True:
            print("Patron encontrado! Presione ESC para omitir o ENTER para aceptar")
            
            # Save the corner coordinates into imagePoints, this is the image point coordinates
            #imagePoints.push_back(corners2); 
            # Store all corner coordinates of each picture in objectPoints, the object point coordinates
            #objectPoints.push_back(objp);
            #objpoints.append(objp)
            
            #--- Sometimes, Harris cornes fails with crappy pictures, so
            corners2 = cv2.cornerSubPix(gray,corners,(11,11),(-1,-1),criteria)
            #imgpoints.append(corners2)

            # Draw and display the corners
            cv2.drawChessboardCorners(img, (nCols,nRows), corners2,ret)
            cv2.imshow('img',img)

            # cv2.waitKey(0)
            k = cv2.waitKey(0) & 0xFF
            if k == 27: #-- ESC Button
                print("Imagen Omitida")
                imgNotGood = fname
                continue

            print("Imagen Aceptada")
            nPatternFound += 1
            objpoints.append(objp)
            imgpoints.append(corners2)

            # cv2.waitKey(0)
        else:
            imgNotGood = fname


cv2.destroyAllWindows()

if (nPatternFound > 1):
    print("Encontradas %d buenas imagenes" % (nPatternFound))
   
    ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(objpoints, imgpoints, gray.shape[::-1],None,None)

    #Quitar distorcionde la imagen
    #Imagen con distorcion(curvada.jpg) que se debe generar previamiente antes de ejecutar el programa
    img = cv2.imread(workingFolder + "/curvada.jpg")
    h,  w = img.shape[:2]
    print("Imagen para elminar distorcion: ", imgNotGood)
    newcameramtx, roi=cv2.getOptimalNewCameraMatrix(mtx,dist,(w,h),1,(w,h))

    # undistort
    mapx,mapy = cv2.initUndistortRectifyMap(mtx,dist,None,newcameramtx,(w,h),5)
    dst = cv2.remap(img,mapx,mapy,cv2.INTER_LINEAR)

    # crop the image
    x,y,w,h = roi
    dst = dst[y:y+h, x:x+w]
    print("ROI: ", x, y, w, h)

    cv2.imwrite(workingFolder + "/calibresult.png",dst)
    print("Imagen calibrada guardada como calibresult.png")
    print("Matrix de Calibracion: ")
    print(mtx)

    print("Distorcion: ", dist)


    #--------- Guarda los resultados
    filename = workingFolder + "/cameraMatrix.txt"
    np.savetxt(filename, mtx, delimiter=',')
    filename = workingFolder + "/cameraDistortion.txt"
    np.savetxt(filename, dist, delimiter=',')

    mean_error = 0
    #Efecto de compatibilidad con versiones de python
    try:
        # Python 2
        r = xrange
    except NameError:
        # Python 3, xrange is now named range
        r = range
    for i in r(len(objpoints)):
        imgpoints2, _ = cv2.projectPoints(objpoints[i], rvecs[i], tvecs[i], mtx, dist)
        error = cv2.norm(imgpoints[i],imgpoints2, cv2.NORM_L2)/len(imgpoints2)
        mean_error += error

    print("Error total: ", mean_error/len(objpoints))
    

else:
    print("Para calibrar se nesecita por lo menos 9 buenas imagenes... intenta de nuevo")
