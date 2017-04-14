from os import listdir, mkdir
import csv
from shutil import copy
from collections import Counter
import numpy as np

w = csv.writer(open('video_class_label.txt','wb'))

vids = listdir('../dataset/mat_to_csv/')

vid_no = 1

for v in vids:

    r = csv.reader(open('../dataset/mat_to_csv/'+v,'rb'))

    lst = []
    for row in r:
        lst.append(row)

    for i in range(0,len(lst)-60,30):
        mkdir('../dataset/all_data/'+str(vid_no).zfill(10))

        label = []
        k = 1
        for j in range(i,i+60):
            np.save('../dataset/all_data/'+str(vid_no).zfill(10)+'/'+str(k).zfill(10)+'.npy',lst[j][:-1])
            label.append(lst[j][-1])
            k += 1

        label = Counter(label).most_common(1)

        w.writerow([str(vid_no).zfill(10),label])

        vid_no += 1

        




