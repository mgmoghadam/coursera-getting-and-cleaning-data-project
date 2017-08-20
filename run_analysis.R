# 1.Merges the training and the test sets to create one data set.

xtest = read.table("./UCI HAR Dataset/test/X_test.txt")
ytest = read.table("./UCI HAR Dataset/test/y_test.txt")
subjecttest = read.table("./UCI HAR Dataset/test/subject_test.txt")

# create a test data set
testset = xtest

# merge the subject column into the test data set
testset = mutate(testset, subject = as.integer(subjecttest$V1))

# merge the activity label column into the test data set
test.activityf = factor(ytest$V1, levels=activity.labels$V1, labels=activity.labels$V2)

# read and combine training data

read.dataset <- function(xfilename, yfilename, subjectfilename) {
    df = read.table(xfilename) # observed variables per observation
    y.df = read.table(yfilename) # activity label per observation
    subject.df = read.table(subjectfilename) # subject per observation
    df = mutate(df, subject = subject.df$V1)
    df = mutate(df, activity = y.df$V1)
}

trainset = read.dataset("./UCI HAR Dataset/train/X_train.txt", 
                        "./UCI HAR Dataset/train/y_train.txt",
                        "./UCI HAR Dataset/train/subject_train.txt")

testset = read.dataset("./UCI HAR Dataset/test/X_test.txt", 
                       "./UCI HAR Dataset/test/y_test.txt",
                       "./UCI HAR Dataset/test/subject_test.txt")

data = rbind(testset, trainset)

# 2.Extracts only the measurements on the mean and standard deviation for each measurement.

# Read the feature labels
feature.labels = read.table("./UCI HAR Dataset/features.txt")
feature.labels = mutate(feature.labels, varname=paste0("V", V1))

# Select only feature labels that contain mean or std (case insensitive) AND are not angle measurements
filtered.feature.labels = filter(feature.labels, grepl('(mean|std)', V2, ignore.case=T) & !grepl('^angle\\(', V2))
vars = c(filtered.feature.labels$varname, c("subject", "activity"))

data2 = select(data, one_of(vars))
# 3.Uses descriptive activity names to name the activities in the data set

activity.labels = read.table("./UCI HAR Dataset/activity_labels.txt")

activityf = factor(data2$activity, levels=activity.labels$V1, labels=activity.labels$V2)

data3 = mutate(data2, activity = activityf)


# 4.Appropriately labels the data set with descriptive variable names.

library(data.table)
oldnames = filtered.feature.labels$varname
newnames = as.character(filtered.feature.labels$V2)
setnames(data3, old=oldnames, new=newnames)

write.table(data3, file="HAR-timewindow.txt", row.name=FALSE)
df = read.table("HAR-timewindow.txt", header=TRUE)

# 5.From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

library(reshape2)

data.melt = melt(data3, id=c("subject", "activity"), measure.vars=newnames)

mean.data = dcast(data.melt, subject + activity ~ variable, mean)

oldnames = names(mean.data)[3:length(names(mean.data))]
newnames = as.character(sapply(oldnames, function(n) paste0("subject-activity-mean-", n)))
setnames(mean.data, old=oldnames, new=newnames)

# look at the first 3 subjects
head(mean.data, n=18)

write.table(mean.data, file="HAR-subject-activity-mean.txt", row.name=FALSE)

for(name in names(mean.data)) { print(name) }    
