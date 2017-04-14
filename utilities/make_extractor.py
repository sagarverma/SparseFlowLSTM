
from os import listdir,mkdir

fout = open('extract_images.sh','wb')



folders = listdir('../dataset/EgoOutside/vids/')

i = 1

for f in ['fpsi']:
    vids = listdir('../dataset/EgoOutside/vids/' + f)

    #mkdir('../dataset/EgoOutside/frames/' + f)

    for v in vids:
        #mkdir('../dataset/EgoOutside/frames/' + f + '/' + v[:-4])

        fout.write('ffmpeg -i "../dataset/EgoOutside/vids/' + f + '/' + v + '" -vf scale=320:240 -r 15 "../dataset/EgoOutside/frames/'  + f + '/' + v[:-4] + '/%10d.png" &\n')

        if i % 44 == 0:
            fout.write('wait\n')

        i += 1

"""

vids = listdir('../dataset/EgoOutside/vids/')
   
i = 1
   
   
   
for v in vids:
    mkdir('../dataset/EgoOutside/frames/' + v[:-4])
   
    fout.write('ffmpeg -i "../dataset/EgoOutside/vids/'  + v + '" -vf scale=320:240 -r 15 "../dataset/EgoOutside/frames/'  + v[:-4] + '/%10d.png" &\n')
   
    if i % 44 == 0:
        fout.write('wait\n')
   
    i += 1
"""
