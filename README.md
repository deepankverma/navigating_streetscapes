# Navigating Streetscapes
CITYLID: A large-scale categorized aerial Lidar dataset for street-level research.


## Overview
This repository is dedicated to providing openly accessible categorized aerial Lidar datasets along with detailed methodology for data preparation. 
The repository has two main parts. First, It explains the process for raw point cloud categorization. The process includes the fusion of other datasets, such as 2D street shapefiles and shadow maps. Secondly, it provides supporting codes and scripts to replicate the steps leading to the final dataset. It also 
provides example scripts to reproduce a [research](https://doi.org/10.1016/j.scs.2023.104673) study focused on generating city-wide street cross-sections, which 
uses the categorized point cloud data generated in the repository.


## Getting Started


### Dataset Overview

The raw point-cloud dataset and detailed street map used in this project were obtained from the Geodata Portal of Berlin state, accessible via [FISBroker](https://fbinter.stadt-berlin.de/fb/index.jsp). The Lidar dataset is provided in *.las 1.4 format, a lossless point cloud storage format, with a density of 9.8 points per square meter, and last updated on 02.03.2021. Additionally, the Berlin geoportal offers a comprehensive city street plan provided as shapefiles. This street plan was created through meticulous digitization based on an extensive street survey conducted between 2014 and 2015, with the final publication in 2019. It includes detailed subdivisions of streets into driveways, bike paths, median strips, walkways, parking areas, and other street infrastructure.

### Prerequisites

The research utilizes a range of scripts and algorithms, including LAStools, lidR, PDAL, GDAL, QGIS, and ArcGIS Pro, to process Lidar and GIS-based polygon data for extracting cross-sectional details.

## Methodology

### Primary Classification
In this study, the LASTools software suite was employed for point cloud classification. LASTools consists of a set of efficient multicore command line tools designed for processing Lidar datasets. Within this suite, tools such as lasground, lasheight, and lasclassify were utilized to classify the dataset. The study area encompasses 1,060 tiles of the Lidar dataset, which were processed accordingly to conduct primary classification into categories such as ground, trees, buildings, and unassigned points. Notably, water bodies were not identified during the process, as the classifier does not differentiate between open ground and water due to their similar point properties. Consequently, water bodies were categorized as part of the ground class.

### Integration of Street Features to the Primary Classification
Due to the distinct data structures of street polygons (2D) and Lidar-based (3D) points, direct integration is not feasible. To address this, we employed the Point Data Abstraction Library (PDAL). PDAL offers a range of filters designed for processing Lidar point clouds. We converted vector-based shapefiles into RGB raster images and utilized "colorize" and "range" filters. These filters merge the raster dataset with the point cloud, enabling the points to adopt the RGB values of the overlapped raster. Scripts for automating this integration process are provided in the designated folder.

### Generation of Solar Radiation maps and fusing the information to the resulting Point-Cloud Dataset
In this study, the ArcGIS-based Solar Radiation pattern generation tool is used to create and calculate shadows. This tool utilizes a hemispherical viewshed algorithm, which takes the Digital Surface Model (DSM) derived from the Lidar dataset as input to generate shadows. The solar profile is established using georeferencing information calculated from the DSM. Subsequently, the single-band raster containing shadow information is projected onto the final point cloud using PDAL. Additionally, a new field named "UserData" is introduced alongside the existing scalar field "Classification," which stores classification codes. This new field represents shadow classes (S1 - S5).

## Accessing the Data

Following data compilation, each point in the Lidar dataset was categorized into (a) one of nine categories, including five street constituents, ground, trees, buildings, and unassigned, and (b) one of five shadow classes. Similar to the tile-based format provided by Geoportal, the fully categorized dataset is also accessible from the HuggingFace database.

## Application of the Data 

The dataset is utilized to create 0.5 Million cross-sections in the entire city of Berlin. The process requires an additional dataset to guide liDR tools to generate cross-sections gradually covering the entire city. The R-based code, along with the required dataset and tools, is provided in the folder.


## License

The Berlin Geoportal provides the dataset using a DL-BY-DE License. [URL].

## References

- Verma, D., Mumm, O., & Carlow, V. M. (2023). Generating citywide street cross-sections using aerial LiDAR and detailed street plan. Sustainable Cities and Society, 96, 104673 [Link to the paper](https://www.sciencedirect.com/science/article/pii/S2210670723002846).



