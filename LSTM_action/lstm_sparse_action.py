from __future__ import division, print_function, absolute_import
from __future__ import division, print_function, absolute_import
import os

os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "1"

import tflearn
from tflearn.layers.core import input_data, fully_connected, reshape
from tflearn.layers.conv import conv_2d, max_pool_2d
from tflearn.layers.recurrent import lstm
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
        sample = np.reshape(sample, (120,32,32))
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

tflearn.config.init_graph (num_cores=4, gpu_memory_fraction=0.5)

dataset_file = 'test.txt'
X, y = sample_preloader(dataset_file, categorical_labels=True)

test_dataset_file = 'train.txt'
X_test, y_test = sample_preloader(test_dataset_file, categorical_labels=True)

inp = input_data(shape=[None, 120, 32, 32], name='input')

reshape_inp = reshape(inp, [-1, 32, 32, 1])

conv1_1 = conv_2d(reshape_inp, 64, 7, strides=4, activation='relu')
pool1 = max_pool_2d(conv1_1, 2, strides=1)

fc1 = fully_connected(pool1, 512, activation='relu')

reshape_pool1 = reshape(fc1, [-1, 120, 512])

lstm_l1 = lstm(reshape_pool1, 512, activation='relu', name='lstm_l1')

net = fully_connected(lstm_l1, 15, activation='softmax', restore=False)

network = regression(net, optimizer='sgd', loss='categorical_crossentropy', learning_rate=0.01)

model = tflearn.DNN(network)

model.fit(X, y, validation_set=[X_test, y_test], n_epoch=1, shuffle=True, show_metric=True, batch_size=128, snapshot_step=500, run_id='LSTM_Action_HUJI')


model.save("../../checkpoints/LSTM_Action_HUJI.tflearn")