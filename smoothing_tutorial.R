# Loading libraries 
library(proj4)
library(rgdal)
library(spdep)
library(maptools)


# Description of the shapefile, and saving it to a variable
getinfo.shape("/us_county_hs_only.shp")
shapefile <-readShapePoly("/us_county_hs_only.shp")


# Set projections 
proj4string(shapefile)<-CRS("+proj=longlat +init=epsg:4326")
shapefile_albers <-spTransform(shapefile, CRS("+init=ESRI:102003"))


# Converting the shapefile into a data frame and substituting any missing values with 0 
shapefile_df <- as(shapefile_albers, "data.frame")
shapefile_df[is.na(shapefile_df)] <-0


# Nearest neighbours are calculated as points, so we need to specify the coordinate system to be used for our shapefile,
# as well as the list of counties that we'll be calculating neighbors for.
coords <- coordinates(shapefile_albers)
IDs<-row.names(as(shapefile_albers, "data.frame"))


# Creating a list of neighbors for each location, using the 5 nearest neighbors 
knn50 <- knn2nb(knearneigh(coords, k = 50), row.names = IDs)
knn50 <- include.self(knn50)



# Creating the localG statistic for each of counties, with a k-nearest neighbor value of 5, and round this to 3 decimal places
localGvalues <- localG(x = as.numeric(shapefile_df$hs_pct), listw = nb2listw(knn50, style = "B"), zero.policy = TRUE)
localGvalues <- round(localGvalues,3)

# Create a new data frame that only includes the county fips codes and the G scores
new_df <- data.frame(shapefile_df$GEOID)
new_df$values <- localGvalues

#Huzzah! We're now ready to export this CSV, and visualize away!
write.table(row.names = FALSE,new_df, file = "smooooothstuff.csv", sep=",")


