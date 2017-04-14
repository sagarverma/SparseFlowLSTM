import csv
from random import shuffle, sample
import ast

r = csv.reader(open('video_class_label.txt','rb'), delimiter=',')
w1 = csv.writer(open('trainVideos.txt','wb'), delimiter=' ')
w2 = csv.writer(open('testVideos.txt','wb'), delimiter=' ')

lst = []

id_map = {}

class_id = 0

for row in r:
    #l = ast.literal_eval(row[1])[0][0]

    #if l != 'DontCare':
    #    if l not in id_map:
    #        id_map[l] = class_id
    #        class_id += 1

    lst.append(row)


shuffle(lst)
shuffle(lst)
shuffle(lst)

print len(lst)

train = lst[:150]
test = lst[150:]

for t in train:
    w1.writerow(t)

for t in test:
    w2.writerow(t)





