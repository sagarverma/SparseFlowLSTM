from xml.dom import minidom
import sys
from os import listdir
import csv

annotations_path = '../../dataset/EgoOutside/annotations/'
annotations = listdir(annotations_path)

for annotation_file in annotations:
    if 'eaf' in annotation_file:
        xmldoc = minidom.parse(annotations_path + annotation_file)
        timestamplist = xmldoc.getElementsByTagName('TIME_SLOT')
        tierlist = xmldoc.getElementsByTagName('TIER')

        w = csv.writer(open(annotations_path + annotation_file[:-4] + ".txt", 'w'), delimiter=' ')

        write_list = []

        timestamp = {}
        annotation = {}

        for s in timestamplist :
            timestamp[s.attributes['TIME_SLOT_ID'].value] = int(s.attributes['TIME_VALUE'].value)

        annotationslist = tierlist[0].getElementsByTagName('ANNOTATION')

        for s in annotationslist :
            time_ref_1 = s.getElementsByTagName('ALIGNABLE_ANNOTATION')[0].attributes['TIME_SLOT_REF1'].value
            time_ref_2 = s.getElementsByTagName('ALIGNABLE_ANNOTATION')[0].attributes['TIME_SLOT_REF2'].value
            label = s.getElementsByTagName('ANNOTATION_VALUE')[0].firstChild.nodeValue

            class_this = label.split(' ')[0]
            if class_this == 'Open' or class_this == 'Closed':
                class_this = 'Passenger'
            if class_this == 'Gathering' or class_this == 'Queue':
                class_this = 'Standing'                  
            if class_this == '':
                class_this = label.split(' ')[1]

            w.writerow([int(timestamp[time_ref_1] / 1000.0 * 30), int(timestamp[time_ref_2] / 1000.0 * 30), class_this])


