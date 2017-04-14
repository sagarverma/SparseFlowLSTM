from os import listdir,mkdir
import csv
import cv2
import numpy as np




vids = listdir('../../dataset/multimodal_FPV/multimodal_dataset/sparse_csvs_32x32/')

	
for v in vids:

	mkdir('../../dataset/multimodal_FPV/multimodal_dataset/out_imgs_32x32/'+ v[:-4])

	r = csv.reader(open('../../dataset/multimodal_FPV/multimodal_dataset/sparse_csvs_32x32/' + v,'rb'))
 
	for row in r:
		break

	img_no = 1
	for row in r:
		temp = []
		for i in range(0,2048,2):
			#print float(row[i]),float(row[i+1])
			temp.append([float(row[i]),float(row[i+1])])

		temp = np.asarray(temp)

		#print temp.shape
		temp = temp.reshape((32,32,2))

		np.save('../../dataset/multimodal_FPV/multimodal_dataset/out_imgs_32x32/'+ v[:-4] + '/' + str(img_no).zfill(4) +'.npy',temp)

		img_no += 1

			

	

