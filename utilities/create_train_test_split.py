from os import listdir
import csv
from random import shuffle 
import numpy as np 

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]

#{'plug': 2, 'none': 0, 'cut': 6, 'mark': 8, 'take': 1, 'clean': 5, 'measure': 7, 'put': 3, 'polish': 4, 'wear': 9}

annotations = listdir('../../dataset/EgoOutside/annotations/')

w = csv.writer(open('../3DCNN/all_samples.txt', 'w'), delimiter=' ')

out_path = '/home/sagan/Huji_SF_dataset/'

class_map = {}

class_id = 0

sample_no = 1
for annotation in annotations[6:]:
    if 'txt' in annotation:
        print annotation
        r1 = csv.reader(open('../../dataset/EgoOutside/annotations/' + annotation[:-4] + '.txt', 'r'), delimiter=' ')

        lst = []
        for row in r1:
            break
        for row in r1:
            #print row, annotation
            if ':' not in "".join(row):
                class_this = row[2]
                if class_this not in class_map:
                    class_map[class_this] = class_id
                    class_id += 1

                lst.append([int(row[0]), int(row[1]), class_map[class_this]])
            else:
                if 'Cooking' not in class_map:
                    class_map['Cooking'] = class_id
                    class_id += 1 
                lst.append([1, len(listdir('../../dataset/EgoOutside/frames/cooking/' + annotation[:-4])), class_map['Cooking']])

        r2 = csv.reader(open('../../dataset/EgoOutside/csvs_32x32/' + annotation[:-4] + '.csv', 'r'))

        for row in r2:
            break

        all_rows = []

        row_no = 0
        for row in r2:
            temp1 = []
            temp2 = []
            for k in range(0,len(row),6):
                temp1.append(float(row[k+1]))
                temp2.append(float(row[k+2]))
            all_rows.append([temp1,temp2])

            row_no += 1

        all_splits = []
        for l in lst:
            all_splits.append(all_rows[int(l[0]):int(l[1])])

        for i in range(len(lst)):
            for chunk in chunks(all_splits[i], 60):
                if len(chunk) == 60:  
                    w.writerow([str(sample_no).zfill(10) + '.npy', lst[i][2]])

                    np.save(out_path + str(sample_no).zfill(10) + '.npy', np.asarray(chunk))
                    sample_no += 1




print len(class_map.keys()), class_map

"""
shuffle(train)
shuffle(train)
shuffle(train)

shuffle(test)
shuffle(test)
shuffle(test)

for t in train:
    w1.writerow(t)

for t in test:
    w2.writerow(t)
"""