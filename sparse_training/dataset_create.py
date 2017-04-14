from os import listdir, mkdir
import csv
from shutil import copy

w = csv.writer(open('video_class_label.txt','wb'))



vids = listdir('../../dataset/multimodal_FPV/multimodal_dataset/out_imgs_32x32/')

for v in vids:
    print v[3:5]
    w.writerow([v,int(v[3:5])-1])

