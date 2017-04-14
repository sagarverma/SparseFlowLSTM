from __future__ import division, print_function, absolute_import
from __future__ import division, print_function, absolute_import
import os

os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "1"

import tflearn
from tflearn.layers.core import input_data, dropout, fully_connected, reshape
from tflearn.layers.conv import conv_2d, max_pool_2d, conv_3d, max_pool_3d
from tflearn.layers.estimator import regression
from tflearn.layers.merge_ops import merge_outputs, merge
from tflearn.optimizers import Momentum
import numpy as np
import csv

def to_categorical(y, nb_classes):
    y = np.asarray(y, dtype='int32')
    if not nb_classes:
        nb_classes = np.max(y)+1
    Y = np.zeros((len(y), nb_classes))
    Y[np.arange(len(y)),y] = 1.
    return Y

class Preloader(object):
    def __init__(self, array, function):
        self.array = array
        self.function = function

    def __getitem__(self, id):
        if type(id) in [list, np.ndarray]:
            return [self.function(self.array[i]) for i in id]
        elif isinstance(id, slice):
            return [self.function(arr) for arr in self.array[id]]
        else:
            return self.function(self.array[id])

    def __len__(self):
        return len(self.array)

class SamplePreloader(Preloader):
    def __init__(self, path):
        fn = lambda x: self.preload(x)
        super(SamplePreloader, self).__init__(path, fn)

    def preload(self, path):
        sample = np.load(path)
        sample = np.reshape(sample, (120,1024)).T
        sample = np.reshape(sample, (32, 32, 120))
        return sample


class LabelPreloader(Preloader):
    def __init__(self, array, n_class=None, categorical_label=True):
        fn = lambda x: self.preload(x, n_class, categorical_label)
        super(LabelPreloader, self).__init__(array, fn)

    def preload(self, label, n_class, categorical_label):
        if categorical_label:
            #TODO: inspect assert bug
            #assert isinstance(n_class, int)
            return to_categorical([label], n_class)[0]
        else:
            return label

def sample_preloader(target_path, categorical_labels=True):
    with open(target_path, 'r') as f:
        samples, labels = [], []
        for l in f.readlines():
            l = l.strip('\n').split()
            samples.append(l[0])
            labels.append(int(l[1]))

    n_classes = np.max(labels) + 1
    X = SamplePreloader(samples)
    Y = LabelPreloader(labels, n_classes, categorical_labels)

    return X, Y

tflearn.config.init_graph (num_cores=4, gpu_memory_fraction=0.3)

dataset_file = 'test.txt'
X, y = sample_preloader(dataset_file, categorical_labels=True)

test_dataset_file = 'train.txt'
X_test, y_test = sample_preloader(test_dataset_file, categorical_labels=True)

inp = input_data(shape=[None, 32, 32, 120], name='input')
reshape_inp = reshape(inp, [-1, 32, 32, 120, 1])

conv1_1 = conv_3d(reshape_inp, 30, [17,17,20], strides=[1,2,2,4,1], activation='relu', name="conv1_1")
pool1 = max_pool_3d(conv1_1, [1,2,2,13,1], strides=[1,1,1,13,1])

reshape_pool1 = reshape(pool1, [-1, 8, 8, 360])

conv2_1 = conv_2d(reshape_pool1, 100, 3, activation='relu', name="conv2_1")
pool2 = max_pool_2d(conv2_1, 2)

fc1 = fully_connected(pool2, 400, activation='relu', name="fc1")
fc2 = fully_connected(fc1, 50, activation='relu', name="fc2")
fc3 = fully_connected(fc2, 15, activation='softmax', name="fc3")

network = regression(fc3, optimizer='sgd', loss='categorical_crossentropy', learning_rate=0.01)

model = tflearn.DNN(network)

model.load("3D_CNN_HUJI.tflearn")
model.fit(X, y, validation_set=[X_test, y_test], n_epoch=1, shuffle=True, show_metric=True, batch_size=256, snapshot_step=500, run_id='3D_CNN_HUJI')
