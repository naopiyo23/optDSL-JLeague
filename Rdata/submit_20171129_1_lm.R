#����--------------------------------------------------------------------------------

#�g�p���C�u����
library(dplyr)
library(stringr)
library(ggplot2)
library(randomForest)
library(knitr)
library(caret)

#�f�[�^�Ǎ�
train<-read.csv("C:/study/JLeague/motodata/train.csv",
                header=TRUE, stringsAsFactors=FALSE, fileEncoding="utf-8")
test<-read.csv("C:/study/JLeague/motodata/test.csv",
               header=TRUE, stringsAsFactors=FALSE, fileEncoding="utf-8")
condition<-read.csv("C:/study/JLeague/motodata/condition.csv",
                    header=TRUE, stringsAsFactors=FALSE, fileEncoding="UTF-8")
stadium<-read.csv("C:/study/JLeague/motodata/stadium.csv",
                  header=TRUE, stringsAsFactors=FALSE, fileEncoding="utf-8")
sample<-read.csv("C:/study/JLeague/motodata/sample_submit.csv",
                 header=FALSE, stringsAsFactors=FALSE, fileEncoding="utf-8")
train_add<-read.csv("C:/study/JLeague/motodata/train_add.csv",
                    header=TRUE, stringsAsFactors=FALSE, fileEncoding="utf-8")
condition_add<-read.csv("C:/study/JLeague/motodata/condition_add.csv",
                        header=TRUE, stringsAsFactors=FALSE, fileEncoding="UTF-8")

# #�f�[�^�m�F
# str(train)
# str(test)
# str(stadium)
# str(sample)
# str(train_add)
# #�����L��
# anyNA(train)
# anyNA(test)
# anyNA(stadium)
# anyNA(train_add)

#�O�����p�֐�--------------------------------------------------------------------------------
#train/test�f�[�^�̑O���������{���܂��B
#train/test,stadium,condition�ɑ΂��ĕϐ����H���s���A���������������f�[�^��ԋp���܂��B
#train/test��condition��id�ŁAtrain/test��stadium�̓X�^�W�A�����Ō������Ă��܂��B
#data:train�܂���test�f�[�^��ݒ�
#data_condition:condition�f�[�^��ݒ�
#data_stadium:stadium�f�[�^��ݒ�
F_pre <- function(data,data_condition,data_stadium,traindataflag) {
  #--------------train_all/test���H--------------
  #tmp�쐬
  data_tmp<-data
  #�umatch�v�̉��H �߂Ɠ��𕪂���i���l�݂̂ɂ���j
  #�߁i���l�̂݁j�̗�usetu�v�ǉ� ��F��P�ߑ�Q����1
  data_tmp<-data_tmp %>%
    #�umatch�v��1���ڂ���4���ڂ�؂�o��
    dplyr::mutate(setu=substring(data$match, 1, 4) %>%
                    #�؂�o����������́h��h��""�ɒu������
                    gsub(pattern="��", replacement="", fixed = TRUE) %>%
                    #�؂�o����������́h�߁h��""�ɒu������
                    gsub(pattern="��", replacement="", fixed = TRUE))
  
  #�usetu�v�S�p���p�ϊ�
  for (i in 1:nrow(data_tmp)) {
    data_tmp[i,"setu"] <- chartr("�P�Q�R�S�T�U�V�W�X�O", 
                                 "1234567890",
                                 data_tmp[i,"setu"])
  }
  
  #���ځi���l�̂݁j�̗�usetu_nitime�v�ǉ� ��F��P�ߑ�Q����2
  data<-data_tmp %>%
    #�umatch�v��5���ڂ���6���ڂ�؂�o��
    dplyr::mutate(Snitime=substring(data_tmp$match, 5, 6) %>%
                    #�؂�o����������́h��h��""�ɒu������
                    gsub(pattern="��", replacement="", fixed = TRUE) %>%
                    #�؂�o����������́h�߁h��""�ɒu������
                    gsub(pattern="��", replacement="", fixed = TRUE))
  
  #�ugameday�v���H ���Ɠ��Ɨj���i�j���j�𕪂���@
  #�ugameday�v�̌��ugameM�v��ǉ� ��F03/10(�y)��03
  data_tmp<-data_tmp %>%
    #�ugameday�v��1���ڂ���2���ڂ�؂�o��
    dplyr::mutate(gameM=substring(data_tmp$gameday, 1, 2))
  
  #�ugameday�v�̓��ugameD�v��ǉ� ��F03/10(�y)��10
  data_tmp<-data_tmp %>%
    #�ugameday�v��4���ڂ���5���ڂ�؂�o��
    dplyr::mutate(gameD=substring(data_tmp$gameday, 4, 5))
  
  #�uyear�v�ugameM�v�ugameD�v�������ugameYMD�v�ǉ� ��F2012 03/10(�y)��20120310
  data_tmp<-data_tmp %>%
    dplyr::mutate(gameYMD= paste(data_tmp$year,data_tmp$gameM,data_tmp$gameD,sep=""))
  
  #gameday�̗j���ugameW�v��ǉ�  ��F03/10(�y)�˓y
  #�ugameW�v���쐬�i�l�͂��ׂău�����N�j
  data_tmp$gameW = ""
  #�ugameday�v��"���h�̕������܂܂�Ă���s�́ugameW�v��"��"��ݒ�@�ȉ��j�������{
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("��", data_tmp$gameday)] = "��"
  data_tmp$gameW[grep("�y", data_tmp$gameday)] = "�y"
  #�ugameW�v���X�V����Ă��邩�m�F
  table(data_tmp$gameW)
  
  #gameday�̏j���t���O�ugameWS�v��ǉ�  ��F03/10(�y�E�j)�ˏj����:1�A�j�Ȃ�:0
  #�ugameWS�v���쐬�i�l�͂��ׂ�0�j
  data_tmp$gameWS = "0"
  #�ugameday�v��"�j�h�̕������܂܂�Ă���s�́ugameWS�v��1��ݒ�
  data_tmp$gameWS[grep("�j", data_tmp$gameday)] = 1
  #�ugameWS�v���X�V����Ă��邩�m�F
  table(data_tmp$gameWS)
  
  #gameday�̋x�݂̓��i�y���j���j�t���O�ukyuujitu�v��ǉ�
  #�x�݂̓��i�y���j���j�𒊏o
  data_tmp$kyuujitu = "0"
  data_tmp$kyuujitu <- ifelse(data_tmp$gameWS==1,1,0)
  data_tmp$kyuujitu[grep("�y", data_tmp$gameday)] = 1
  data_tmp$kyuujitu[grep("��", data_tmp$gameday)] = 1
  
  # tv "/"�ŕ���"���f�А��Ƃ��ꂼ��ŕ��f���ꂽ���ǂ����B [�쐬��]
  # tv "/"�ŕ���" �������X�g���쐬
  tv_tmp <- strsplit(data_tmp$tv, "�^")
  
  # ���f���ꂽ�e���r�ǂ̐��utv_num�v��ǉ� ��F�X�J�p�[�I�^�X�J�p�[�I�v���~�A���T�[�r�X�^�e���ʁ�3
  data_tmp<-data_tmp %>%
    #tv_tmp�̊e�s�̗v�f�����utv_num�v�ɐݒ�
    dplyr::mutate(tv_num=lapply(tv_tmp,length) %>%
                    unlist())
  
  #�e���r�ǂ̎�ސ��m�F
  # a<-unlist(tv_tmp)
  # table(a)
  
  #time���J�e�S����
  #�C�ے��̒�`
  #0���`3�� �c �����A3���`6�� �c �������A6���`9�� �c ��
  #9���`12�� �c ���O�A12���`15�� �c ���߂��A15���`18�� �c �[��
  #18���`21�� �c ��̏��ߍ��A21���`24�� �c ��x��
  data_tmp<-data_tmp %>%
    #�utimezone�v��1���ڂ���2���ڂ�؂�o��
    dplyr::mutate(timezone=as.integer(substring(data_tmp$time, 1, 2)))
  
  for (i in 1:nrow(data_tmp)) {
    if(0 <= data_tmp[i,"timezone"] && data_tmp[i,"timezone"] < 15){
      data_tmp[i,"timezone"] <- "��"
    }else if(15 <= data_tmp[i,"timezone"] && data_tmp[i,"timezone"] < 18){
      data_tmp[i,"timezone"] <- "�[��"
    }else if(18 <= data_tmp[i,"timezone"] && data_tmp[i,"timezone"] < 24){
      data_tmp[i,"timezone"] <- "��"
    }
  }
  
  #time�́F�폜
  data_tmp$timeInt <-""
  data_tmp$timeInt <- as.integer(gsub(data_tmp$time,pattern=":", replacement="", fixed = TRUE))
  
  #timeInt�����ԒP�ʂɕϊ�
  data_tmp<-data_tmp %>%
    dplyr::mutate(timeInt_c = floor(timeInt/100))
  
  #�U�X�p���Â��U�X�p�N�T�c�Q�n�ɕϊ�
  data_tmp$home[grep("�U�X�p����", data_tmp$home)] = "�U�X�p�N�T�c�Q�n"
  data_tmp$away[grep("�U�X�p����", data_tmp$away)] = "�U�X�p�N�T�c�Q�n"
  
  #���茧�������^���������㋣�Z��𒷍�s�����^�����������ǂ܂藤�㋣�Z��ɕϊ�
  #data_tmp$stadium[grep("���茧�������^���������㋣�Z��", data_tmp$stadium)] = "����s�����^�����������ǂ܂藤�㋣�Z��"
  
  #--------------stadium���H--------------
  #tmp�쐬
  data_stadium_tmp <- data_stadium
  #�s���{�����o�uaddress_ken�v
  #�uaddress�v��1�����ڂ���u�s���{���v�̂����ꂩ���o������܂ł̕������؂�o��
  data_stadium_tmp$address_ken=substring(data_stadium_tmp$address,
                                         1,
                                         regexpr("�s|��|�{|��",data_stadium$address,useBytes=F))
  #���s�{�����{�ɂ�����O�ɓs������邽�ߏC��
  data_stadium_tmp$address_ken[grep("���s", data_stadium_tmp$address_ken)] = "���s�{"
  data_stadium_tmp$address_ken <- as.character(data_stadium_tmp$address_ken)
  
  #--------------condition���H--------------
  #tmp�쐬
  data_condition_tmp <- data_condition
  
  
  #�����_�ݒ�
  for (i in 1:nrow(data_condition_tmp)) {
    if(data_condition_tmp$home_score[i] > data_condition_tmp$away_score[i]){
      data_condition_tmp$home_katiten[i] <- 3
      data_condition_tmp$away_katiten[i] <- 0
      
    }else if(data_condition_tmp$home_score[i] < data_condition_tmp$away_score[i]){
      data_condition_tmp$home_katiten[i] <- 0
      data_condition_tmp$away_katiten[i] <- 3
      
    }else{
      data_condition_tmp$home_katiten[i] <- 1
      data_condition_tmp$away_katiten[i] <- 1
    }
  }
  
  
  #--------------�f�[�^����--------------
  #data_tmp��condition��ΐ�J�[�hid����Ɍ���
  data_tmp<-dplyr::left_join(data_tmp, data_condition_tmp, by="id")
  
  #data_tmp��stadium������("stadium" = "name")
  data_new<-dplyr::left_join(data_tmp, data_stadium_tmp, by=c("stadium" = "name"))
  
  #traindata�̏ꍇ
  if(traindataflag){
    #y/capa�Ŏ��e���uy2�v���Z�o
    data_new$y2<-data_new$y/data_new$capa
  }
  
  #�^�ϊ�
  # len <- length(data_new)
  # for(count in 1:len){
  #   if(is.character(data_new[1,count])){
  #     data_new[count]<-lapply(data_new[count],as.factor)
  #   }
  # }

  data_new$setu<-as.integer(data_new$setu)
  data_new$gameM<-as.integer(data_new$gameM)
  data_new$gameD<-as.integer(data_new$gameD)
  data_new$gameYMD<-as.integer(data_new$gameYMD)
  data_new$gameWS<-as.integer(data_new$gameWS)
  
  return(data_new)
}

#���P------------------------------------------------------------------------------------------
#��������͗\�����x�����コ���邽�߂̊֐�������܂��B

#�w�肵��ID�̃f�[�^���폜
F_outlier <- function(df,outlier) {
  data_new<-df %>%
    dplyr::filter(id!=outlier)
  return(data_new)
}

#setu�̉��H(setu��x�Ő܂�Ԃ��Ă݂�)
F_setu2 <- function(df,x) {
  df<-df %>%
    dplyr::mutate(setu2=abs(x-setu))  #abs�͐�Βl
  return(df)
}

#timeInt_c�̉��H(timeInt��x�Ő܂�Ԃ���*-1)
F_timeInt_c2 <- function(df,x) {
  df<-df %>%
    dplyr::mutate(timeInt_c2=abs(x-timeInt_c)*-1)  #abs�͐�Βl
  return(df)
}

#year�̉��H(timeInt��x�Ő܂�Ԃ���*-1)
F_year2 <- function(df,x) {
  df<-df %>%
    dplyr::mutate(year2=abs(x-year)*-1)  #abs�͐�Βl
  return(df)
}


#�`�[�����Ƃ̊O��l���폜
F_outlier_all <- function(df) {
  df_tmp <- df
  uni <- unique(df_tmp$home)
  len <- length(uni)
  for(count in 1:len){
    out_tmp <-df_tmp %>%
      dplyr::filter(home==uni[count])
    
    x <- out_tmp$y
    Q1 <- quantile(x)[2]		# ��1�l���ʐ�
    Q3 <- quantile(x)[4]		# ��3�l���ʐ�
    IQRx <- IQR(x)			# �l���ʔ͈�
    outlierU<- x[x < Q1-(IQRx*1.5)]		# �����̊O��l
    outlierO<- x[x > Q3+(IQRx*1.5)]		# �㑤�̊O��l
    
    if(length(outlierO) != 0){
      out_tmp <- out_tmp %>%
        dplyr::filter(y>=min(outlierO))
      
      len2 <- nrow(out_tmp)
      for(count2 in 1:len2){
        df_tmp <-df_tmp %>%
          dplyr::filter(df_tmp$id != out_tmp$id[count2])
        
      }
    }
  }
  return(df_tmp)
}

#�\���l�̏C��
F_pred_fix <- function(pred,tr,te) {
  min<-min(tr$y)
  print(min)
  pred2<-ifelse(pred < min, min,
                ifelse(pred > te$capa, te$capa, pred))
  return(pred2)
}

#main------------------------------------------------------------------------------------------
#����������ۂɃf�[�^�����H���ă��f�������܂��B
#add�f�[�^�ǉ�
train_all <- dplyr::bind_rows(train, train_add)
condition_all <- dplyr::bind_rows(condition, condition_add)

#train/test�̑O�������{
train_new <- F_pre(train_all,condition_all,stadium, traindataflag=TRUE)
test_new <- F_pre(test,condition_all,stadium, traindataflag=FALSE)


###CSV�o��
# write.table(train_new, file="C:/study/JLeague/submit/train_new.csv",
#             quote=FALSE, sep=",", row.names=F, col.names=T)
# write.table(test_new, file="C:/study/JLeague/submit/test_new.csv",
#             quote=FALSE, sep=",", row.names=F, col.names=T)

#�ϐ����H-----------------------------------

#���ϋq�����̃f�[�^�폜
train_new <- F_outlier(train_new,15699)
#�}���m�X��̊O��l�폜
train_new <- F_outlier(train_new,15127)

#�`�[�����Ƃ̊O��l���폜
train_new<-F_outlier_all(train_new)

# J1/J2�̃f�[�^
lm_train_j1 <- train_new %>% filter(stage == "�i�P")
lm_train_j2 <- train_new %>% filter(stage == "�i�Q")
lm_test_j1 <- test_new %>% filter(stage == "�i�P")
lm_test_j2 <- test_new %>% filter(stage == "�i�Q")

#setu�����H
F_linearplot2(lm_train_j1,"setu") %>% plot()
F_linearplot2(lm_train_j2,"setu") %>% plot()
lm_train_j1 <- F_setu2(lm_train_j1,3)
lm_train_j2 <- F_setu2(lm_train_j2,3)
F_linearplot2(lm_train_j1,"setu2") %>% plot()
F_linearplot2(lm_train_j2,"setu2") %>% plot()

lm_test_j1 <- F_setu2(lm_test_j1,3)
lm_test_j2 <- F_setu2(lm_test_j2,3)

#timeInt_c�����H
F_linearplot(lm_train_j1,"timeInt_c") %>% plot()
F_linearplot(lm_train_j2,"timeInt_c") %>% plot()
lm_train_j1 <- F_timeInt_c2(lm_train_j1,18)
lm_train_j2 <- F_timeInt_c2(lm_train_j2,15)
F_linearplot2(lm_train_j1,"timeInt_c2") %>% plot()
F_linearplot2(lm_train_j2,"timeInt_c2") %>% plot()

lm_test_j1 <- F_timeInt_c2(lm_test_j1,18)
lm_test_j2 <- F_timeInt_c2(lm_test_j2,15)

#year�����H
# F_linearplot(lm_train_j1,"year") %>% plot()
# F_linearplot(lm_train_j2,"year") %>% plot()
# lm_train_j1 <- F_year2(lm_train_j1,2012)
# F_linearplot(lm_train_j1,"year2") %>% plot()
# 
# lm_test_j1 <- F_year2(lm_test_j1,2012)

#�����m�F
anyNA(lm_train_j1)
anyNA(lm_train_j2)
anyNA(lm_test_j1)
anyNA(lm_test_j2)

#���f���쐬-----------------------------------
#���e����\��������A�e�X�^�W�A���̎��e�l����������
#�\���ϋq���������Z�o����B

#�ϐ��I��
lm_train_j1_2<-dplyr::select(lm_train_j1, y2, tv_num, capa, setu2, home, kyuujitu)
lm_train_j2_2<-dplyr::select(lm_train_j2, y2, tv_num, capa, setu2, home, kyuujitu)
lm_test_j1_2<-dplyr::select(lm_test_j1, tv_num, capa, setu2, home, kyuujitu)
lm_test_j2_2<-dplyr::select(lm_test_j2, tv_num, capa, setu2, home, kyuujitu)

# ###�d��A����
# #family:�ړI�ϐ��̊m�����z�ƃ����N�֐��̐ݒ�(����͐��K���z�ƍP���ʑ�)
lm_j1<-glm(y2 ~ ., data=lm_train_j1_2, family=gaussian(link="identity"))
lm_j2<-glm(y2 ~ ., data=lm_train_j2_2, family=gaussian(link="identity"))

#test�ɓ��Ă͂�
pred_j1<-predict(lm_j1, lm_test_j1_2, type="response")
pred_j2<-predict(lm_j2, lm_test_j2_2, type="response")

#�\���W�q��*capa�ŗ\���W�q�l�����v�Z
pred_j1<-round(pred_j1*lm_test_j1_2$capa)
pred_j2<-round(pred_j2*lm_test_j2_2$capa)

#�\���l�␳
pred_j1<-F_pred_fix(pred_j1,lm_train_j1,lm_test_j1)
pred_j2<-F_pred_fix(pred_j2,lm_train_j2,lm_test_j2)

###submit�`���ϊ�
submit_j1<-data.frame(id=lm_test_j1[,"id"], pred=pred_j1)
submit_j2<-data.frame(id=lm_test_j2[,"id"], pred=pred_j2)

submit_all <- dplyr::bind_rows(submit_j1, submit_j2)

###CSV�o��(�w�b�_�[�Ȃ�)
write.table(submit_all, file="C:/study/JLeague/submit/submit_20171125_1_lm.csv",
            quote=FALSE, sep=",", row.names=FALSE, col.names=FALSE)

#########�ϐ��I�� rmse���m�F�������Ƃ��p
#test�ɓ��Ă͂�
pred_j1<-predict(lm_j1, lm_train_j1_2, type="response")
pred_j2<-predict(lm_j2, lm_train_j2_2, type="response")

#�\���W�q��*capa�ŗ\���W�q�l�����v�Z
pred_j1<-round(pred_j1*lm_train_j1_2$capa)
pred_j2<-round(pred_j2*lm_train_j2_2$capa)

#�\���l�␳
pred_j1<-F_pred_fix(pred_j1,lm_train_j1,lm_train_j1_2)
pred_j2<-F_pred_fix(pred_j2,lm_train_j2,lm_train_j2_2)

sqrt(sum((lm_train_j1$y - pred_j1)^2)/nrow(lm_train_j1_2))
sqrt(sum((lm_train_j2$y - pred_j2)^2)/nrow(lm_train_j2_2))

########


#########�ϐ��I�� rmse���m�F�������Ƃ��p�Q
lm_train_j1_2<-dplyr::select(lm_train_j1, y, tv_num, capa, setu2, home, kyuujitu)
lm_train_j2_2<-dplyr::select(lm_train_j2, y, tv_num, capa, setu2, home, kyuujitu)
# J1���`��A�A10������������
model_j1 <- train(
  y ~ .,
  data = lm_train_j1_2,
  method = "lm",
  trControl = trainControl(method = "cv", number = 10))
# J1���f����RMSE
model_j1$results$RMSE

# J2���`��A�A10������������
model_j2 <- train(
  y ~ .,
  data = lm_train_j2_2,
  method = "lm",
  trControl = trainControl(method = "cv", number = 10))
# J2���f����RMSE
model_j2$results$RMSE

# J1���f����J2���f���̌��ʂ𓝍������Ƃ���RMSE
se <- model_j1$results$RMSE^2 * nrow(lm_train_j1_2) + model_j2$results$RMSE^2 * nrow(lm_train_j2_2)
n <- nrow(lm_train_j1_2) + nrow(lm_train_j2_2)
rmse <- sqrt(se / n)
rmse
###############################################################################################
#��������̓f�[�^���e�������E�m�F���邽�߂̃R�[�h�ł��B--------------------------------------
#--------------���Ђ��}�֐��P�i�ϋq�������j--------------
#df �f�[�^�t���[��
#dfx ��Ldf����W�v�������P�ʂ̗�i�`�[���ʂ̏ꍇhome���w��j
F_boxplot <- function(df,dfx) {
  bp<-ggplot(df, aes(y=y, x=dfx,fill = dfx)) 
  bp<-bp+geom_boxplot(alpha=0.5,colour="gray30")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))+
    theme(legend.position = "none")
  bp
}

#--------------���Ђ��}�֐��Q�i�W�q���j--------------
#df �f�[�^�t���[��
#dfx ��Ldf����W�v�������P�ʂ̗�i�z�[���`�[���ʂ̏ꍇhome���w��j
F_boxplot2 <- function(df,dfx) {
  bp<-ggplot(df, aes(y=(y/capa), x=dfx,fill = dfx)) 
  bp<-bp+geom_boxplot(alpha=0.5,colour="gray30")+
    theme(axis.text.x = element_text(angle = 45, hjust = 1))+
    theme(legend.position = "none")
  bp
}
dev.off() 
#���s
#train_new��J1�AJ2�ɕ�����
tmpJ1 <- dplyr::filter(train_new,train_new$stage == "�i�P")
tmpJ2 <- dplyr::filter(train_new,train_new$stage == "�i�Q")
#�z�[���`�[���ʊϋq������
F_boxplot(tmpJ1,tmpJ1$home)
F_boxplot(tmpJ2,tmpJ2$home)
#�z�[���`�[���ʏW�q��
F_boxplot2(tmpJ1,tmpJ1$home)
F_boxplot2(tmpJ2,tmpJ2$home)
#�X�^�W�A���ʊϋq������
F_boxplot(tmpJ1,tmpJ1$stadium)
F_boxplot(tmpJ2,tmpJ2$stadium)
#�X�^�W�A���ʏW�q��
F_boxplot2(tmpJ1,tmpJ1$stadium)
F_boxplot2(tmpJ2,tmpJ2$stadium)
#�s���{���ʊϋq������
F_boxplot(tmpJ1,tmpJ1$address_ken)
F_boxplot(tmpJ2,tmpJ2$address_ken)
#�s���{���ʏW�q��
F_boxplot2(tmpJ1,tmpJ1$address_ken)
F_boxplot2(tmpJ2,tmpJ2$address_ken)
#������ʊϋq������
F_boxplot(tmpJ1,tmpJ1$timezone)
F_boxplot(tmpJ2,tmpJ2$timezone)

#--------------���`�����m�F--------------
#group_by_key�Ɋm�F����������w��
#�W�q�l����}�����邽�߂̃f�[�^��ԋp
F_linearplot <- function(df,group_by_key) {
  
  g_dat <- df %>%
    dplyr::group_by_(group_by_key) %>%
    dplyr::summarise(y_mean = mean(y)) %>%
    dplyr::ungroup(.) %>%
    ggplot(., aes_(x = as.name(group_by_key), y = as.name("y_mean"))) + geom_line()
  return(g_dat)
  
}
#group_by_key�Ɋm�F����������w��
#�W�q����}�����邽�߂̃f�[�^��ԋp
F_linearplot2 <- function(df,group_by_key) {
  
  g_dat <- df %>%
    dplyr::group_by_(group_by_key) %>%
    dplyr::summarise(y_mean = mean(y2)) %>%
    dplyr::ungroup(.) %>%
    ggplot(., aes_(x = as.name(group_by_key), y = as.name("y_mean"))) + geom_line()
  return(g_dat)
  
}
#group_by_key�Ɋm�F����������w��
#�W�q���ΐ��I�b�Y��}�����邽�߂̃f�[�^��ԋp
F_linearplot3 <- function(df,group_by_key) {
  
  g_dat <- df %>%
    dplyr::group_by_(group_by_key) %>%
    dplyr::summarise(y_mean = mean(y2)) %>%
    dplyr::ungroup(.) %>%
    dplyr::mutate(log_odds=log(y_mean/(1-y_mean))) %>%
    ggplot(., aes_(x = as.name(group_by_key), y = as.name("log_odds"))) + geom_line()
  return(g_dat)
  
}

#�W�q�l��
F_linearplot(train_new,"capa") %>% plot()
F_linearplot(train_new,"setu") %>% plot()
F_linearplot(train_new,"gameM") %>% plot() #3������12��
F_linearplot(train_new,"gameD") %>% plot()
dplyr::filter(train_new,train_new$year == 2012) %>%
  F_linearplot("gameYMD") %>% plot()
dplyr::filter(train_new,train_new$year == 2013) %>%
  F_linearplot("gameYMD") %>% plot()
dplyr::filter(train_new,train_new$year == 2014) %>%
  F_linearplot("gameYMD") %>% plot()
F_linearplot(train_new,"tv_num") %>% plot()
F_linearplot(train_new,"temperature") %>% plot()

#�W�q��
F_linearplot2(train_new,"capa") %>% plot()
F_linearplot2(train_new,"setu") %>% plot()
F_linearplot2(train_new,"gameM") %>% plot() #3������12��
F_linearplot2(train_new,"gameD") %>% plot()
dplyr::filter(train_new,train_new$year == 2012) %>%
  F_linearplot2("gameYMD") %>% plot()
dplyr::filter(train_new,train_new$year == 2013) %>%
  F_linearplot2("gameYMD") %>% plot()
dplyr::filter(train_new,train_new$year == 2014) %>%
  F_linearplot2("gameYMD") %>% plot()
F_linearplot2(train_new,"tv_num") %>% plot()
F_linearplot2(train_new,"temperature") %>% plot()

#train_new��J1�AJ2�ɕ�����
tmpJ1 <- dplyr::filter(train_new,train_new$stage == "�i�P")
tmpJ2 <- dplyr::filter(train_new,train_new$stage == "�i�Q")

#������
#J1J2���ɂS������ԒႭ�A�P�P���P�Q��������
#J1�̂U���͎������̂����Ȃ�
F_linearplot2(tmpJ1,"gameM") %>% plot() #3������12��
F_linearplot2(tmpJ2,"gameM") %>% plot() #3������12��

table(tmpJ1$gameM)
table(tmpJ2$gameM)

#�߂���(���[�O�͂R���͂��߂���X�^�[�g�A�P�Q���P�T�ڂ�����ŏI���)
#���[�O�n�܂�ƏI���͗\�z�ʂ�W�q���ǂ�
F_linearplot2(tmpJ1,"setu") %>% plot()
F_linearplot2(tmpJ2,"setu") %>% plot()

table(tmpJ1$setu)
table(tmpJ2$setu)

#�ϐ����H(setu��3�Ő܂�Ԃ��Ă݂�)
tmpJ1_2<-tmpJ1 %>%
  dplyr::mutate(setu2=abs(3-setu))  #abs�͐�Βl
F_linearplot2(tmpJ1_2,"setu2") %>% plot()

#�ϐ����H(setu��3�Ő܂�Ԃ��Ă݂�)
tmpJ2_2<-tmpJ2 %>%
  dplyr::mutate(setu2=abs(3-setu))  #abs�͐�Βl
F_linearplot2(tmpJ2_2,"setu2") %>% plot()


#point
plot(train_new$temperature, train_new$y2)

#--------------�����j���̐��`���m�F--------------

#�d����������i�����i�j�������j�j�𒊏o
F_heijitu <- function(df) {
  df_g<-df %>%
    dplyr::filter(gameW=="��"|
                    gameW=="��"|
                    gameW=="��"|
                    gameW=="��"|
                    gameW=="��") %>%
    dplyr::filter(gameWS!=1)
  return(df_g)
}

#�x�݂̓��i�y���j���j�𒊏o
F_kyuujitu <- function(df) {
  df_g<-df %>%
    dplyr::filter(gameW=="�y"|
                    gameW=="��"|
                    gameWS==1)
  
  return(df_g)
}

#train_new��J1�AJ2�ɕ�����
tmpJ1 <- dplyr::filter(train_new,train_new$stage == "�i�P")
tmpJ2 <- dplyr::filter(train_new,train_new$stage == "�i�Q")

#�j�����Ƃ̎��������m�F
#J1�͕����͐��j�����A�y�����Ɠy�j���̂ق�������
table(tmpJ1$gameW) 
#J2�������͐��j�����A�A�y�����Ɠ��j���̂ق�������
table(tmpJ2$gameW) 

#j1�̃f�[�^���m�F�i���Ȃ��B�B�j
table(F_heijitu(tmpJ1)$gameW)
table(F_kyuujitu(tmpJ1)$gameW)
#j2�̃f�[�^���m�F
table(F_heijitu(tmpJ2)$gameW)
table(F_kyuujitu(tmpJ2)$gameW)

#J1�̕����̎����J�n���Ԃ��Ƃ̏W�q�l�����m�F
F_linearplot(F_heijitu(tmpJ1),"timeInt_c") %>% plot()
#J1�̕����̎����J�n���Ԃ��Ƃ̏W�q�����m�F
F_linearplot2(F_heijitu(tmpJ1),"timeInt_c") %>% plot()

#�ϐ����H(timeInt��14�Ő܂�Ԃ���*-1)
tmpJ1_2<-tmpJ1 %>%
  dplyr::mutate(timeInt_c2=abs(14-timeInt_c)*-1)  #abs�͐�Βl
F_linearplot2(F_heijitu(tmpJ1_2),"timeInt_c2") %>% plot()

#J2�̋x���̎����J�n���Ԃ��Ƃ̏W�q�l�����m�F
F_linearplot(F_kyuujitu(tmpJ2),"timeInt_c") %>% plot()
#J2�̋x���̎����J�n���Ԃ��Ƃ̏W�q�����m�F
F_linearplot2(F_kyuujitu(tmpJ2),"timeInt_c") %>% plot()

#�ϐ����H(timeInt��15�Ő܂�Ԃ���*-1)
tmpJ2_2<-tmpJ2 %>%
  dplyr::mutate(timeInt_c2=abs(15-timeInt_c)*-1)  #abs�͐�Βl
F_linearplot2(F_heijitu(tmpJ2_2),"timeInt_c2") %>% plot()

#�`�[������
g <- ggplot(lm_train_j1, aes(x = capa, y = y, colour = home)) + geom_point()
print(g)

#--------------�Y�a���b�Y�m�F--------------
train_reds<-dplyr::filter(train_new,home=="�Y�a���b�Y")
train_mari<-dplyr::filter(train_new,home=="���l�e�E�}���m�X")
F_linearplot2(train_reds,"setu") %>% plot()
F_linearplot2(train_mari,"setu") %>% plot()

F_linearplot2(train_reds,"year") %>% plot()
F_linearplot2(train_mari,"year") %>% plot()

F_linearplot2(train_new,"year") %>% plot()

#--------------�c���m�F--------------
#���f���쐬
# ###�d��A����
# #family:�ړI�ϐ��̊m�����z�ƃ����N�֐��̐ݒ�(����͐��K���z�ƍP���ʑ�)
lm_j1<-glm(y2 ~ ., data=lm_train_j1_2, family=gaussian(link="identity"))
lm_j2<-glm(y2 ~ ., data=lm_train_j2_2, family=gaussian(link="identity"))

#train�ɓ��Ă͂�
pred_j1<-predict(lm_j1, lm_train_j1_2, type="response")
pred_j2<-predict(lm_j2, lm_train_j2_2, type="response")

#�\���W�q��*capa�ŗ\���W�q�l�����v�Z
pred_j1<-round(pred_j1*lm_train_j1_2$capa)
pred_j2<-round(pred_j2*lm_train_j2_2$capa)

###submit�`���ϊ�
submit_j1<-data.frame(id=lm_train_j1[,"id"], pred=pred_j1)
submit_j2<-data.frame(id=lm_train_j2[,"id"], pred=pred_j2)

submit_all <- dplyr::bind_rows(submit_j1, submit_j2)
lm_train_all <- dplyr::bind_rows(lm_train_j1, lm_train_j2)

#�z�[���`�[��, �A�E�F�C�`�[��, �X�^�W�A��, ���e�l��, �C���ɒ���
#�c���̑傫�����ɕ��ׂ�
zan<-data.frame(lm_train_all, Res=abs(lm_train_all$y-submit_all$pred), pred=submit_all$pred, 
                dif=lm_train_all$y-submit_all$pred) %>%
  dplyr::select(id, Res, y, pred, dif, stage, home, away, stadium, capa, setu, tv_num, timeInt_c) %>%
  dplyr::arrange(desc(Res))

#�m�F(�c���̐�Βl�̑傫����)
#�\���l�������l��葽��
kable(head(zan %>%
             dplyr::filter(dif<=0), n=25))

#�\���l�������l��菭�Ȃ�
kable(head(zan %>%
             dplyr::filter(dif>0), n=25))



#--------------���̑��m�F�p�֐�--------------
#��̒l�����Ȃ���𒊏o
OnlyVariablePrint <- function(table){
  len <- length(names(table))
  for(VarCount in 1:len){
    var <- length(levels(factor(table[,names(table)[VarCount]])))
    if( var == 1 ){
      print( names(table)[VarCount])
    }
  }
}