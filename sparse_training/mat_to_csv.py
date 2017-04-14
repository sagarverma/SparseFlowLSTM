from os import listdir
import csv
from scipy.io import loadmat

files = listdir('../dataset/egocentric')

vid_no = 1

for f in files:
    if f[-4:] == '.mat':

        print f

        mat = loadmat('../dataset/egocentric/'+f)

        if 'traj' in mat:
            w = csv.writer(open('../dataset/mat_to_csv/'+str(vid_no).zfill(3)+'.csv', 'wb'))

            x1 = mat['traj'][0][0][9].T
            y1 = mat['traj'][0][0][10].T
            x2 = mat['traj'][0][0][11].T
            y2 = mat['traj'][0][0][12].T
            x3 = mat['traj'][0][0][13].T
            y3 = mat['traj'][0][0][14].T
            l = mat['traj'][0][0][18][0][0][2]

            for i in range(x1.shape[0]):
                w.writerow(list(x1[i]) + list(y1[i]) + [l[i][0][0]])

            vid_no += 1


