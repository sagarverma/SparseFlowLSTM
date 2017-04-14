import csv
from random import shuffle

r = csv.reader(open('../3DCNN/all_samples.txt','r'), delimiter=' ')

w1 = csv.writer(open('../3DCNN/train.txt','w'), delimiter=' ')
w2 = csv.writer(open('../3DCNN/test.txt','w'), delimiter=' ')

classes = {}
for row in r:
    if row[1] not in classes:
        classes[row[1]] = [row[0]]

    else:
        classes[row[1]].append(row[0])

for k in classes.keys():
    class_samples = classes[k]

    shuffle(class_samples)

    for cs in class_samples[:1500]:
        w1.writerow([cs, k])

    for cs in class_samples[1500:]:
        w2.writerow([cs, k])

