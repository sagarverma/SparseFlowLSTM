from os import listdir, mkdir

#dirs = listdir('../dataset/EgoOutside/vids')
#dones = listdir('../dataset/EgoOutside/csvs_32x32')

fout = open('batch_sparse_compute.sh','w')

i = 0

#for d in dirs:
videos = listdir('../dataset/EgoOutside/vids/running')

for vid in videos:
    #if vid[:-4] + '.csv' not in dones:
       mkdir('../dataset/EgoOutside/frames/running/' + vid[:-4])

       fout.write("./Vid2OpticalFlowCSV/sparse_flow -d " + "/dev/null" + " -c config.xml -o " + 
                "../dataset/EgoOutside/csvs_32x32/running/" + 
                vid[:-4].replace(' ','\ ').replace('&', '\&').replace('\#', '\\#').replace("'", "\\'").replace("(", "\(").replace(")", "\)") + 
                ".csv -v ../dataset/EgoOutside/vids/running/"  + 
                vid.replace(' ','\ ').replace('&', '\&').replace('\#', '\\#').replace("'", "\\'").replace("(", "\(").replace(")", "\)") + " &\n")

       i += 1
       if i%48 == 0:
           fout.write("wait\n")
