library(rlas)
library(lidR)
library(raster)
library(ggplot2)
library(rgdal)
library(sf)
library(abind)
library(reticulate)
library(tidyverse)
library(DescTools)


#######load shapefile############################################
shape <- shapefile("C:\\Users\\isu_v\\Desktop\\Berlin_data_for_other_pc\\attached_tile_m_10_final_cross_pair_berlin.shp")
head(shape)
shape[is.na(shape$location_1)] <- 0

shapenew = data.frame(shape)


count_las = 1
iteration_count = 0


for (each in Sys.glob(file.path("C:\\Users\\isu_v\\Downloads\\LAS_downloads\\Nord\\4","*.las"))) {

  print(each)
  
  las_name = strsplit(each, "_")[[1]]
  loc1 = las_name[6]
  loc2 = las_name[7]
  
  lasfile = paste(loc1,"_",loc2,"_1",sep = "")
  
  print(lasfile)
  
  sub_shape = shape[shapenew$location_1 == lasfile,]
  
  sub_shape = as.data.frame(sub_shape)
  
  if (nrow(sub_shape) == 0) {
    next
  }

  las <- readLAS(each, select = "* -RGB")
  las_check(las)
  
  
  for (i in 1:nrow(sub_shape)) {
    

    
    if (isTRUE(sub_shape$lat[i] == sub_shape$lat[i+1])==TRUE) {
      
      iteration_count = iteration_count+1
      print(iteration_count)
      print(i)
      print(iteration_count)
      
      print(sub_shape$lat_or[i])
      print(sub_shape$long_or[i])
      
      width = sub_shape$road_width[i]
      
      p1 <- c(as.double(sub_shape$long_or[i]), as.double(sub_shape$lat_or[i]))
      p2 <- c(as.double(sub_shape$long_or[i+1]), as.double(sub_shape$lat_or[i+1]))
      
      print(p1)
      print(p2)
      
      bbox = st_bbox(las)
      print(bbox)
      
      
      if (((p1[1]>bbox[1] & p1[1]<bbox[3]) & (p1[2]>bbox[2] & p1[2]<bbox[4])) & ((p2[1]>bbox[1] & p2[1]<bbox[3]) & (p2[2]>bbox[2] & p2[2]<bbox[4]))) {
  

        las_tr <- clip_transect(las, p1, p2, width = 10, xz = TRUE)
        
        las_tr1 <- classify_noise(las_tr, sor(15,7))
        las_denoise <- filter_poi(las_tr1, Classification != LASNOISE)
        
        las_denoise <- filter_poi(las_denoise, Classification != 1)
        
        DSM <- las_denoise@data[ , .(Z = max(Z)), by = list(X = plyr::round_any(X, 0.5))]
        

       
        
        
        ###################dataframe#########################
        
        
        
        main <- as.data.frame(las_denoise@data)
        
        
        
        main$X = main$X + abs((min(main$X)))
        
        
        ##Dividing the section into two equal halves
        
        half1 = filter(main, X< max(main$X)/2)
        half2 = filter(main, X> max(main$X)/2)
        

        

        ##2. CORRIDOR WIDTH // AVERAGE HEIGHT OF THE CORRIDOR FROM THE GROUND
        
        corr1 = filter(main, Classification == 13 | Classification == 14 | Classification == 15 | Classification == 16 | Classification == 17 | Classification == 18)
        
        extent1 = min(corr1$X)
        extent2 = max(corr1$X)
        
        corr_width = extent2 - extent1
        width1 = ifelse(is.infinite(corr_width),0,corr_width)   
        
        main_height = mean(corr1$Z)
        
        ##Dividing section into three halves
        # corr2 = filter(main, Classification == 13 | Classification == 14 | Classification == 15 | Classification == 16 | Classification == 17 | Classification == 18 | Classification == 5)
        one_third1 = filter(main, X< max(main$X)/3)
        one_third2 = filter(main, ((X< (max(main$X)/3)*2)) & (X> max(main$X)/3))
        one_third3 = filter(main, (X< max(main$X)) & (X> (max(main$X)/3)*2))
        
        
        #############################################figures############################################
        
        # print(DSM)
        
        #http://sape.inf.usi.ch/quick-reference/ggplot2/colour
        
        ##for shadow-based cross-section
        
        # cols <- c("1" = "#023047", "2" = "#219ebc", "3" = "#8ecae6", "4" = "#ffb703", "5" = "#fb8500" )
        # # cols <- c("1" = "#fb8500", "2" = "#ffb703", "3" = "#8ecae6", "4" = "#219ebc", "5" = "#023047" )
        # 
        # plots = ggplot(las_denoise@data) +
        #   #aes(X,Z, color = factor(las_denoise@data$Classification)) +
        #   aes(X,Z, color = factor(las_denoise@data$R)) +
        #   geom_point(size = 1) + 
        #   geom_line(data = DSM, color = "black", lwd=0.25) +
        #   # scale_size_manual(values=c(1,2,3,4,5,6))+
        #   coord_equal() + 
        #   #theme_minimal() +
        #   theme_void() + 
        #   theme(legend.position="none")+
        #   ylim(main_height-10, 100)+
        #   # scale_colour_brewer(palette = "Greys", direction = -1)
        #   scale_colour_manual(values = cols)
        
        # ggsave(plots, file=paste0(i,"_", lasfile, "_shadow_", sub_shape$lat[i], "_", sub_shape$longi[i], ".png"), width = 25, height = 12.5, units = "cm")
        
        
        ##for classification-based cross-section
        
        
        cols <- c("0" = "0xFF", "1" = "#FEFFFF", "2" = "black", "3" = "0xFF", "4" = "0xFF", "5" = "chartreuse4", "6" = "brown", "13" = "deeppink",
                  "14" = "darkturquoise", "15" = "brown1", "16" = "darkorange", "17" = "darkgrey", "18" = "darkcyan" )
        
        plots = ggplot(las_denoise@data) +
          #aes(X,Z, color = factor(las_denoise@data$Classification)) +
          aes(X,Z, color = factor(las_denoise@data$Classification)) +
          geom_point(size = 1) + 
          geom_line(data = DSM, color = "black", lwd=0.25) +
          # scale_size_manual(values=c(1,2,3,4,5,6))+
          coord_equal() + 
          # theme_minimal() +
          theme_void() +
          theme(legend.position="none")+
          ylim(main_height-10, 100)+
          scale_colour_manual(values = cols)
        
        ggsave(plots, file=paste0("C:\\Users\\isu_v\\Desktop\\Final_outputs\\Nord\\image_outputs_new\\",i,"_", lasfile, "_class_", sub_shape$lat[i], "_", sub_shape$longi[i], ".png"), width = 25, height = 12.5, units = "cm")
        
        ############################################################################################################################
        
        
        ##3_4. ROADWAY CONNECTED / WIDTH
        
        road1 = filter(half1, Classification == 16)
        extent1 = min(road1$X)
        extent2 = max(road1$X)
        
        width1 = extent2 - extent1
        width1 = ifelse(is.infinite(width1),0,width1)
        
        roadway_width_1 = width1
        
        
        road2 = filter(half2, Classification == 16)
        extent3 = min(road2$X)
        extent4 = max(road2$X)
        
        width2 = extent4 - extent3
        width2 = ifelse(is.infinite(width2),0,width2)
        
        roadway_width_2 = width2
        
        
        ##Total Width
        
        road_width = roadway_width_1 + roadway_width_2
        
        ##To see if roadway is connected
        
        if((width1 > 0 && width2 > 0) & ((extent3-extent2) >= -0.5 && (extent3-extent2) <= 0.5)){
          
          road_connect = 1
        
          }else if ((width1 > 0 && width2 > 0) & (extent3-extent2) > 0.5) { 
            
            road_connect = 2
   
          } else if (road_width > 0){ 
            
            road_connect = 1 
            
            } else {road_connect = 0}
        
     
        
        ##5_6. PEDESTRIAN AVAILABILITY / WIDTH
        
        ped1 = filter(half1, Classification == 13)
        extent1 = min(ped1$X)
        extent2 = max(ped1$X)
        
        width1 = extent2 - extent1
        width1 = ifelse(is.infinite(width1),0,width1)
        
        ped_width_1 = width1
        
        
        ped2 = filter(half2, Classification == 13)
        extent3 = min(ped2$X)
        extent4 = max(ped2$X)
        
        width2 = extent4 - extent3
        width2 = ifelse(is.infinite(width2),0,width2)
        
        ped_width_2 = width2
        
        if (width1 > 0 && width2 > 0){
          
          ped_availability = 2
          
        } else if (width1 == 0 && width2 == 0 ){   
          
          ped_availability = 0
          
        } else {
          
          ped_availability = 1
        }
        
        ped_width = ped_width_1 + ped_width_2
        
        ##7_8. PARKING AVAIALABILITY / WIDTH
        
        par1 = filter(half1, Classification == 15)
        extent1 = min(par1$X)
        extent2 = max(par1$X)
        
        width1 = extent2 - extent1
        width1 = ifelse(is.infinite(width1),0,width1)
        
        par_width_1 = width1
        
        par2 = filter(half2, Classification == 15)
        extent3 = min(par2$X)
        extent4 = max(par2$X)
        
        width2 = extent4 - extent3
        width2 = ifelse(is.infinite(width2),0,width2)
        
        par_width_2 = width2
        
        
        
        if (width1 > 0 && width2 > 0){
          
          par_availability = 2
          
        } else if (width1 == 0 && width2 == 0 ){
          
          par_availability = 0
          
        } else {
          
          par_availability = 1
        }
        
        par_width = par_width_1 + par_width_2
        
        
        ##9_10. DIVIDING STRIPS AVAILABILITY / WIDTH
        
        div1 = filter(main, Classification == 17)
        
        extent1 = min(div1$X)
        extent2 = max(div1$X)
        
        width1 = extent2 - extent1
        
        width1 = ifelse(is.infinite(width1),0,width1)
        
        if (width1 > 0){
          
          div_strips_avail = 1
          
        } else {
          
          div_strips_avail = 0
          
        }
        
        div_strips_width = width1
        
        
        ##11_12. BIKEPATH
        
        bik1 = filter(half1, Classification == 14)
        extent1 = min(bik1$X)
        extent2 = max(bik1$X)
        
        width1 = extent2 - extent1
        width1 = ifelse(is.infinite(width1),0,width1)
        
        bik_width_1 = width1
        
        
        bik2 = filter(half2, Classification == 14)
        extent3 = min(bik2$X)
        extent4 = max(bik2$X)
        
        width2 = extent4 - extent3
        width2 = ifelse(is.infinite(width2),0,width2)
        
        bik_width_2 = width2
        
        
        if (width1 > 0 && width2 > 0){
          
          bik_availability = 2
          
        } else if (width1 == 0 && width2 == 0 ){          
          
          bik_availability = 0
          
        } else {
          
          bik_availability = 1
        }
        
        bik_width = bik_width_1 + bik_width_2
        
        
        ##13-19. PRESENCE OF TREES
        
        
        # tree1 = filter(one_third1, Classification == 5)
        # 
        # if (nrow(tree1) > 5){
        #   
        #   extentxmin = min(tree1$X)
        #   extentxmax = max(tree1$X)
        #   extentzmin = min(tree1$Z)
        #   extentzmax = max(tree1$Z)
        #   
        #   ar = (extentxmax - extentxmin) * (extentzmax - extentzmin)
        #   
        #   treeden1 = nrow(tree1)/ar
        #   
        #   treeht1 = extentzmax - main_height
        #   
        # } else {
        #   
        #   treeden1 = 0
        #   treeht1 = 0
        #   
        # }
        # 
        # tree2 = filter(one_third3, Classification == 5)
        # 
        # if (nrow(tree2) > 5){
        #   
        #   extentxmin = min(tree2$X)
        #   extentxmax = max(tree2$X)
        #   extentzmin = min(tree2$Z)
        #   extentzmax = max(tree2$Z)
        #   
        #   ar = (extentxmax - extentxmin) * (extentzmax - extentzmin)
        #   
        #   treeden2 = nrow(tree2)/ar
        #   
        #   treeht2 = extentzmax - main_height
        #   
        # } else {
        #   
        #   treeden2 = 0
        #   treeht2 = 0
        #   
        # }
        

        
        
        tree1 = filter(half1, Classification == 5)

        if (nrow(tree1) > 5){

          extentxmin = min(tree1$X)
          extentxmax = max(tree1$X)
          extentzmin = min(tree1$Z)
          extentzmax = max(tree1$Z)
          
          tree_1_wd = extentxmax - extentxmin
          tree_1_ht = extentzmax - extentzmin

          ar = (tree_1_wd) * (tree_1_ht)

          treeden1 = nrow(tree1)/ar

          treeht1 = extentzmax - main_height

        } else {

          treeden1 = 0
          treeht1 = 0
          tree_1_wd = 0
          tree_1_ht = 0

        }

        tree2 = filter(half2, Classification == 5)

        if (nrow(tree2) > 5){

          extentxmin = min(tree2$X)
          extentxmax = max(tree2$X)
          extentzmin = min(tree2$Z)
          extentzmax = max(tree2$Z)
          
          tree_2_wd = extentxmax - extentxmin
          tree_2_ht = extentzmax - extentzmin
          
          ar = (tree_2_wd) * (tree_2_ht)

          treeden2 = nrow(tree2)/ar

          treeht2 = extentzmax - main_height

        } else {

          treeden2 = 0
          treeht2 = 0
          tree_2_wd = 0
          tree_2_ht = 0

        }

        if (treeden1 > 0 && treeden2 > 0){

          tree_availability = 2

        } else if (treeden1 == 0 && treeden2 == 0 ){

          tree_availability = 0

        } else {

          tree_availability = 1
        }
        
        
        ###For middle tree
        
        tree3 = filter(one_third2, Classification == 5)
        
        if (nrow(tree3) > 10){
          
          extentxmin = min(tree3$X)
          extentxmax = max(tree3$X)
          extentzmin = min(tree3$Z)
          extentzmax = max(tree3$Z)
          
          ar = (extentxmax - extentxmin) * (extentzmax - extentzmin)
          
          treeden3 = nrow(tree3)/ar
          
          treeht3 = extentzmax - main_height
          
        } else {
          
          treeden3 = 0
          treeht3 = 0
          
        }
        
        if (treeden3 > 0) { 
          middle_tree = 1
        }else {
            middle_tree = 0
          }
        
        
        ##20-24. PRESENCE OF BUILDINGS
        
        buil1 = filter(half1, Classification == 6)
        
        
        if (nrow(buil1) > 5){
          
          extentxmin = min(buil1$X)
          extentxmax = max(buil1$X)
          extentzmin = min(buil1$Z)
          extentzmax = max(buil1$Z)
          
          ar = (extentxmax - extentxmin) * (extentzmax - extentzmin)
          
          builden1 = nrow(buil1)/ar
          
          builht1 = extentzmax - main_height
          
        } else {
          
          builden1 = 0
          builht1 = 0
          
        }
        
        buil2 = filter(half2, Classification == 6)
        
        if (nrow(buil2) > 5){
          
          extentxmin = min(buil2$X)
          extentxmax = max(buil2$X)
          extentzmin = min(buil2$Z)
          extentzmax = max(buil2$Z)
          
          ar = (extentxmax - extentxmin) * (extentzmax - extentzmin)
          
          builden2 = nrow(buil2)/ar
          
          builht2 = extentzmax - main_height
          
        } else {
          
          builden2 = 0
          builht2 = 0
          
        }
        
        if (builden1 > 0 && builden2 > 0){
          
          buil_availability = 2
          
        } else if (builden1 == 0 && builden2 == 0 ){
          
          buil_availability = 0
          
        } else {
          
          buil_availability = 1
        }
        
        ##25----34. SHADOWS
        
        count_total_ped_bike = nrow(filter(main, Classification == 13 | Classification == 14))
        
        shad_lv1_pd = nrow(filter(main, UserData == 1 & (Classification == 13 | Classification == 14))) / count_total_ped_bike
        
        shad_lv2_pd = nrow(filter(main, UserData == 2 & (Classification == 13 | Classification == 14))) / count_total_ped_bike
        
        shad_lv3_pd = nrow(filter(main, UserData == 3 & (Classification == 13 | Classification == 14))) / count_total_ped_bike
        
        shad_lv4_pd = nrow(filter(main, UserData == 4 & (Classification == 13 | Classification == 14))) / count_total_ped_bike
        
        shad_lv5_pd = nrow(filter(main, UserData == 5 & (Classification == 13 | Classification == 14))) / count_total_ped_bike
        
        
        count_total_roadway = nrow(filter(main, Classification == 16))
        
        shad_lv1_ro = nrow(filter(main, UserData == 1 & Classification == 16)) / count_total_roadway
        
        shad_lv2_ro = nrow(filter(main, UserData == 2 & Classification == 16)) / count_total_roadway
        
        shad_lv3_ro = nrow(filter(main, UserData == 3 & Classification == 16)) / count_total_roadway
        
        shad_lv4_ro = nrow(filter(main, UserData == 4 & Classification == 16)) / count_total_roadway
        
        shad_lv5_ro = nrow(filter(main, UserData == 5 & Classification == 16)) / count_total_roadway
        
        ##35 ENCLOSURE
        
        if (is.na(main_height)){
          main_height = 35
        }
        
        DSM_ordered = DSM[order(DSM$X),]
        
        DSM_ordered$Z = DSM_ordered$Z - main_height
        
        area_u_curve = AUC(x=DSM_ordered$X, y=DSM_ordered$Z, method = "trapezoid", absolutearea = TRUE)
        
        auc_normalized = area_u_curve / (width+20)
        
        
        # format(round(x, 2), nsmall = 2)
        
        lon = sub_shape$longi[i]
        lat = sub_shape$lat[i]
        
        
        if (iteration_count==1 & count_las == 1) {
        
        final_dataframe <- data.frame("S.no" = i,"Las_file" = lasfile, "Long" = lon,"Lat" = lat, "Width_1" = width, "Corr_wid_2" = corr_width, "Roadway_conn_3" = road_connect, "Roadway_width_4" = road_width,
                                      "Roadway_1_width_4.1" = roadway_width_1, "Roadway_2_width_4.2" = roadway_width_2,
                                      "Ped_avail_5" = ped_availability, "Ped_width_6" = ped_width, "Ped_1_width_6_1" = ped_width_1, "Ped_2_width_6_2" = ped_width_2,
                                      "Parking_avail_7" = par_availability, "Parking_width_8" = par_width, "Parking_1_width_8.1" = par_width_1, "Parking_2_width_8.2" = par_width_2,
                                      "Dividing_strps_avail_9" = div_strips_avail, "Dividing_strps_width_10" = div_strips_width, "Bikepath_avail_11" = bik_availability,
                                      "Bikepath_width_12" = bik_width,"Bikepath_1_width_12.1" = bik_width_1, "Bikepath_2_width_12.2" = bik_width_2,
                                      "Tree_avail_13" = tree_availability, "Tree_avail_middle_14" = middle_tree, "Tree_density_1_15" = unlist(treeden1), "Tree_1_ht_15.1" = tree_1_ht,
                                      "Tree_1_wd_15.2" = tree_1_wd, "Tree_density_2_16" = unlist(treeden2), "Tree_2_ht_16.1" = tree_2_ht, "Tree_2_wd_16.2" = tree_2_wd,
                                      "Tree_density_3_17"= treeden3, "Tree_height_1_18" = treeht1, "Tree_height_2_19" = treeht2,"Tree_height_3_20" = treeht3, "Building_avail_21" = buil_availability, "Building_den_1_22" = unlist(builden1), 
                                      "Building_den_2_23" = unlist(builden2), "Building_ht_1_24" = builht1, "Building_ht_2_25" = builht2, "Shad_lv1_pd_26" = unlist(shad_lv1_pd),
                                      "Shad_lv2_pd_27" = unlist(shad_lv2_pd), "Shad_lv3_pd_28" = unlist(shad_lv3_pd), "Shad_lv4_pd_29" = unlist(shad_lv4_pd), "Shad_lv5_pd_30" = unlist(shad_lv5_pd),
                                      "Shad_lv1_ro_31" = unlist(shad_lv1_ro), "Shad_lv2_ro_32" = unlist(shad_lv2_ro), "Shad_lv3_ro_33" = unlist(shad_lv3_ro), "Shad_lv4_ro_34" = unlist(shad_lv4_ro),
                                      "Shad_lv5_ro_35" = unlist(shad_lv5_ro), "enclosure_36" = auc_normalized, "height_37" = main_height)
        }else {
        
        
        final_dataframe <- rbind(final_dataframe,list(i,lasfile,lon,lat,width,corr_width,road_connect,road_width,roadway_width_1,roadway_width_2, ped_availability,ped_width,ped_width_1,ped_width_2,
                                                      par_availability, par_width,par_width_1,par_width_2, div_strips_avail, div_strips_width, bik_availability,
                                                      bik_width,bik_width_1,bik_width_2, tree_availability,middle_tree, treeden1,tree_1_ht,tree_1_wd, treeden2,tree_2_ht,tree_2_wd, treeden3, treeht1, treeht2, treeht3, buil_availability, builden1, builden2, builht1, builht2, 
                                                      shad_lv1_pd, shad_lv2_pd, shad_lv3_pd, shad_lv4_pd, shad_lv5_pd, shad_lv1_ro, shad_lv2_ro,shad_lv3_ro,
                                                      shad_lv4_ro, shad_lv5_ro, auc_normalized, main_height))
        
        }
    
    
    
    
      }
    
      i = i+2 } else if (isTRUE(sub_shape$lat[i] != sub_shape$lat[i+1])==TRUE)  {
        
        i = i + 1} else {break
          }
    
  
  } 
  
  write.csv(final_dataframe,file=paste0("C:\\Users\\isu_v\\Desktop\\Final_outputs\\Nord\\dataframe_outputs\\",lasfile,".csv"), row.names = FALSE)
  
  count_las = count_las + 1
  
}

