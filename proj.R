#Load of the data from the Top dataset and the NonTop dataset
#We want to see if the belonging to the Top songs influence the Rap outcome

Top<-read.xlsx("Top.xlsx")
gensongs<-read.xlsx("NonTop.xlsx")

Total=rbind(Top, gensongs)
Total1<-distinct(Total, across(c(tracks)),.keep_all=TRUE)
top_or_not<-rbind(ones(888,1),zeros(8271,1))
Total1<-cbind(Total1,top_or_not)

Rap<-read.xlsx("NonTop.xlsx")
Total1<-Total1[-c(9159), ]

#Remove the column that are not useful for logistic regression

Campione<-Total1[,-c(4,7,9,17)]
head(Campione)

# We inspect some of the Spotify features

attach( Total1 )

ggplot(Total1, aes( Rap_or_not, speechiness, fill= Rap_or_not))+
  geom_boxplot(outlier.size = 1.7, outlier.shape = 20, lwd = 0.8, fatten = 1.2)+
  scale_fill_brewer(palette = "OrRd")+
  labs(x = "", y = "Speechiness")+
  theme_economist()+
  theme(legend.position = "none")

ggplot(Total1, aes( Rap_or_not, danceability, fill= Rap_or_not))+
  geom_boxplot(outlier.size = 1.7, outlier.shape = 20, lwd = 0.8, fatten = 1.2)+
  scale_fill_brewer(palette = "OrRd")+
  labs(x = "", y = "Danceability")+
  theme_economist()+
  theme(legend.position = "none")

ggplot(Total1, aes( Rap_or_not, popularity, fill= Rap_or_not))+
  geom_boxplot(outlier.size = 1.7, outlier.shape = 20, lwd = 0.8, fatten = 1.2)+
  scale_fill_brewer(palette = "OrRd")+
  labs(x = "", y = "Popularity")+
  theme_economist()+
  theme(legend.position = "none")

# We explore the data to see if there is a difference 
#in the speechiness feature between rap and not rap songs

boxplot( speechiness ~ rap_or_not, xlab = 'rap or not', ylab = 'speechiness',)

kruskal.test(popularity ~ rap_or_not, data = Total1)


Total1=na.omit(Total1)
Total1<-Total1[-c(6631),]

#We split the dataset to perform Logistic Regression

trainIndex <- createDataPartition(Total1$rap_or_not, times=1, p=0.8, list=FALSE,)
Total_train <- Total1[trainIndex,]
Total_test <- Total1[-trainIndex,]
detach(Total1)

#We build the Logistic Regression model with all the significant covariates
attach( Total_train )
mod.top = glm( Total_train$rap_or_not ~ popularity + danceability + acousticness + tempo + duration_ms  + valence + speechiness + instrumentalness, family = binomial( link = logit ) )
summary( mod.top)

test_model <- predict(mod.top, newdata = Total_test, type = "response")
detach( Total_train )

soglia=0.4


#We assess the performance of our model: 
valori.reali = Total_test$rap_or_not
valori.predetti = as.numeric(test_model > soglia)
tab= table(valori.reali, valori.predetti)
tab

predold <- prediction(test_model, valori.reali)
perfold <- performance(predold,"tpr","fpr")
plot(perfold,colorize=TRUE)


# % of correctly classified
round( sum( diag( tab ) ) / sum( tab ), 2 )

# % of misclassified:
round( ( tab [ 1, 2 ] + tab [ 2, 1 ] ) / sum( tab ), 2 )

sensitivita =  tab [ 2, 2 ] /( tab [ 2, 1 ] + tab [ 2, 2 ] ) 
sensitivita

specificita = tab[ 1, 1 ] /( tab [ 1, 2 ] + tab [ 1, 1 ] )
specificita

# We filter out some data according to the Cook's distance and the Standardized Residual
mydata <- Total_test %>%
  dplyr::select_if(is.numeric)
predictors <- colnames(mydata)
mydata <- mydata %>%
  mutate(logit = log(test_model/(1-test_model))) %>%
  gather(key = "predictors", value = "predictor.value", -logit)

ggplot(mydata, aes(logit, predictor.value))+
  geom_point(size = 0.5, alpha = 0.5) +
  geom_smooth(method = "loess") + 
  theme_bw() + 
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

#Then we retrain the model

attach( newtrain )

new.top = glm( newtrain$Total_train.rap_or_not ~ popularity + danceability + duration_ms  + valence + speechiness + instrumentalness, family = binomial( link = logit ) )
summary( new.top)

new_model <- predict(new.top, newdata = Total_test, type = "response")
detach( newtrain )

soglia=0.5

new.reali = Total_test$rap_or_not
new.predetti = as.numeric(new_model > soglia)
tabnew= table(new.reali, new.predetti)
tabnew

# % of correctly classified:
round( sum( diag( tabnew ) ) / sum( tabnew ), 2 )

# % of misclassified:
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
