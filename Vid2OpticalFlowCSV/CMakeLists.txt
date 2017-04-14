
PROJECT(Vid2OpticalFlowCSV)
SET(CMAKE_BUILD_TYPE Release)
CMAKE_MINIMUM_REQUIRED( VERSION 2.6 )
FIND_PACKAGE( OpenCV REQUIRED )
ADD_EXECUTABLE(sparse_flow mainfile.cpp stdafx.cpp lk/LKTracker.cpp lk/ImageStats.cpp lk/ConfigReader.cpp util/paramio/XmlParser.cpp util/paramio/XmlStream.cpp util/paramio/XML_Node.cpp util/paramio/ParamIO.cpp util/LensDistortionCorrector.cpp util/Util.cpp util/VideoReaders/OpenCVVideoReader.cpp util/VideoReaders/AbstractVideoReader.cpp lk/TiledMotion.cpp)
TARGET_LINK_LIBRARIES(sparse_flow ${OpenCV_LIBS})

