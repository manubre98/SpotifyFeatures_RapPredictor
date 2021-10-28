library(Rspotify)
library(tidyverse)
library(GGally)
library(wordcloud2) 
library(forcats)
library(data.table)
library(plotly)
library(viridis)
library(hrbrthemes)
library(DT)
library(ggthemes)
library(openxlsx)
library(dplyr)
library(openxlsx)
library(optimbase)
library(caret)
library(broom)

keys <- spotifyOAuth("Stats_Spotify","61e5f4f918a84f84849b871d90a16cac","d41bcecda0b84c978d60bf7aae5c8c84")
user <- getUser("11124062096", token = keys)

user_playlists <- getPlaylists("11124062096", token = keys)
songs1020<-getPlaylistSongs("11124062096", user_playlists$id[1], offset = 0, token = keys)
for (i in 2:50) {
      lung=(user_playlists$tracks[i])/100;
      for (j in 0:floor(lung)) {
      if( j < lung) {
        playlist<-getPlaylistSongs("11124062096", user_playlists$id[i], offset = 100*j, token = keys)
        songs1020<-rbind(songs1020,playlist)
        }
      }
}
      

user_playlists2 <- getPlaylists("11124062096",offset = 50, token = keys)
for (i in 1:34) {
      lung=(user_playlists2$tracks[i])/100;
      for (j in 0:floor(lung)) {
      if( j < lung) {
      playlist<-getPlaylistSongs("11124062096", user_playlists2$id[i], offset = 100*j, token = keys)
      songs1020<-rbind(songs1020,playlist)
        }
      }
}
      

cleantop<-unique.data.frame(songs1020,)
cleantop2<-distinct(cleantop, across(c(tracks)),.keep_all=TRUE)
songsfede<-read.xlsx("SongsFede.xlsx")

generalsongs=rbind(cleantop2,songsfede)
generalsongs1<-unique.data.frame(generalsongs)
generalsongs2<-distinct(generalsongs1, across(c(tracks)),.keep_all=TRUE)





gensongs <- data.frame(generalsongs2$tracks,generalsongs2$artist,generalsongs2$popularity)
  colnames(gensongs) <- c("tracks", "artist","popularity")

songfeatures<-getFeatures(generalsongs2[["id"]][1], token = keys)
id=generalsongs2[["id"]]

for (i in 9004:9062) {
  song1<-getFeatures(id[i], token = keys)
  songfeatures<-rbind(songfeatures,song1)
}
gensongs<-cbind(gensongs,songfeatures)
write.xlsx(gensongs,'NonTop.xlsx')

Top<-read.xlsx("Top.xlsx")
gensongs<-read.xlsx("NonTop.xlsx")

Total=rbind(Top, gensongs)
Total1<-distinct(Total, across(c(tracks)),.keep_all=TRUE)
top_or_not<-rbind(ones(888,1),zeros(8271,1))
Total1<-cbind(Total1,top_or_not)

Rap<-read.xlsx("NonTop.xlsx")
Total1<-Total1[-c(9159), ]


attach( Total1 )

boxplot( speechiness ~ rap_or_not, xlab = 'rap or not', ylab = 'speechiness')

kruskal.test(speechiness ~ rap_or_not, data = Total1)

boxplot( valence ~ rap_or_not, xlab = 'rap or not', ylab = 'popularity')

kruskal.test(popularity ~ rap_or_not, data = Total1)

popnew =(Total1$popularity)^(1/2)
linspeech=(Total1$speechiness)^(-1)+3/4*(Total1$speechiness)
Total1<-cbind(Total1,linspeech)
Total1<-cbind(Total1,popnew)
remove(popnew)
remove(linspeech)

Total1=na.omit(Total1)
Total1<-Total1[-c(6631),]

trainIndex <- createDataPartition(Total1$rap_or_not, times=1, p=0.8, list=FALSE,)
Total_train <- Total1[trainIndex,]
Total_test <- Total1[-trainIndex,]
detach(Total1)



attach( Total_train )


mod.top = glm( Total_train$rap_or_not ~ popularity + danceability + 
                 tempo + acousticness + duration_ms + valence + speechiness + 
                 instrumentalness, family = binomial( link = logit ) )
summary( mod.top)

test_model <- predict(mod.top, newdata = Total_test, type = "response")
detach( Total_train )

soglia=0.4

valori.reali = Total_test$rap_or_not
valori.predetti = as.numeric(test_model > soglia)
tab= table(valori.reali, valori.predetti)
tab

predold <- prediction(test_model, valori.reali)
perfold <- performance(predold,"tpr","fpr")
plot(perfold,colorize=TRUE)

AUCold <- performance(predold,"auc")



# % di casi classificati correttamente:
round( sum( diag( tab ) ) / sum( tab ), 2 )

# % di casi misclassificati:
round( ( tab [ 1, 2 ] + tab [ 2, 1 ] ) / sum( tab ), 2 )

sensitivita =  tab [ 2, 2 ] /( tab [ 2, 1 ] + tab [ 2, 2 ] ) 
sensitivita

specificita = tab[ 1, 1 ] /( tab [ 1, 2 ] + tab [ 1, 1 ] )
specificita


mydata <- Total_test %>%
  dplyr::select_if(is.numeric)
predictors <- colnames(mydata)
mydata <- mydata %>%
  mutate(logit = log(test_model/(1-test_model))) %>%
  gather(key = "predictors", value = "predictor.value", -logit)

ggplot(mydata, aes(logit, predictor.value))+
  geom_point(size = 0.5, alpha = 0.5) +
  geom_smooth(method = "loess") + 
  scale_fill_brewer(palette= "OrRd")+
  theme_economist() + 
  facet_wrap(~predictors, scales = "free_y")

plot(mod.top, which=4, id.n=3)

model.data<- augment(mod.top)%>%
  mutate(index = 1:n())

model.data%>%top_n(3,.cooksd)
ggplot(model.data, aes(index, .std.resid)) + 
  geom_point(aes(color = Total_train.rap_or_not), alpha = .5) +
  theme_bw()

notgood<-model.data %>% 
  filter(abs(.std.resid) > 3)

newtrain<-model.data[-c(notgood$index),]

attach( newtrain )

new.top = glm( newtrain$Total_train.rap_or_not ~ popularity + danceability + 
                 tempo + acousticness + duration_ms + valence + speechiness + 
                 instrumentalness, family = binomial( link = logit ) )
summary( new.top)

new_model <- predict(new.top, newdata = Total_test, type = "response")
detach( newtrain )

soglia=0.41

new.reali = Total_test$rap_or_not
new.predetti = as.numeric(new_model > soglia)
tabnew= table(new.reali, new.predetti)
tabnew

# % di casi classificati correttamente:
round( sum( diag( tabnew ) ) / sum( tabnew ), 2 )

# % di casi misclassificati:
round( ( tabnew [ 1, 2 ] + tabnew [ 2, 1 ] ) / sum( tabnew ), 2 )



sensitivitanew =  tabnew [ 2, 2 ] /( tabnew [ 2, 1 ] + tabnew [ 2, 2 ] ) 
sensitivitanew

specificitanew = tabnew[ 1, 1 ] /( tabnew [ 1, 2 ] + tabnew [ 1, 1 ] )
specificitanew

car::vif(mod.top)


pred <- prediction(new_model, new.reali)
perf <- performance(pred,"tpr","fpr")
plot(perf,colorize=TRUE)

AUC <- performance(pred,"auc")

