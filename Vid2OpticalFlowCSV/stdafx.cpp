#include "stdafx.h"

FILE *STATE_FILE;

int NUM_BLOCKS_X = 10;
int NUM_BLOCKS_Y = 5;
double BLOCK_WIDTH_IMG_WIDTH_RATIO = 10;
double BLOCK_HEIGHT_IMG_HEIGHT_RATIO = 5;

int START_FRAME = 0;
int END_FRAME = INT_MAX;
int FRAME_SKIP = 0;
double LK_FRAME_RESCALE = 0.5;

bool OUT_CANNY_COUNT = true;
bool OUT_GFTT_COUNT = true;
bool OUT_BACK_WARP_ERROR = true;
bool DISPLAY_LK_OUTPUT = true;

int64 RAND_KEY = 1000;

int IMG_WIDTH, IMG_HEIGHT, PROCESSING_WIDTH, PROCESSING_HEIGHT;


float SQAURED_MIN_DIST_FOR_NEW_POINTS = 5;
