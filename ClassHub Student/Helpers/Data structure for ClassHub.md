# Data structure for ClassHub  
  
## User  
userFirstName = User first name  
userLastName = User last name  
userEmail = User email  
userID = The unique identifier of the user  
userType = Student, teacher, admin, and so on  
  
## Class  
className = A human friendly name for the class  
classID = A unique identifier for ClassHub to keep track of which class goes where  
classTeacherID = the user id for the teacher  
classStudents = A list of students enrolled in the class  
  
## Announcement  
announementMakerID = ID of who made the announement  
announcementID = Unique identifier of the announcement  
classID = The class unique identifier  
announcementSendDate = date = What date was the announcement sent  
announementTitle = The heading of the announcement  
announementSubtitle = The body text of the announement  
announementLinks = [string with links]  
  
## Assignment  
assignmentMakerID = ID of who made the assignment  
assignmentID = Unique identifier of the assignment  
assignmentTurnIn = bool = Do you need to turn on the assignment or is it a physical assignment  
classID = The class unique identifier  
assignmentTitle = The heading of the assignment  
assignmentSubtitle = The body text of the assignment  
assignmentDueDate = date = The due date of the assignment  
assignmentRetakes = bool = Does the assignment allow for retakes after the due date?  
assignmentCategory = Grading category for the assignment  
  
## Assignment Submission  
assignmentSubmitterID = UserID  
assignmentID = Assignment ID attached  
classID = Class ID  
submissionID = Unique Identifier for submission  
submissionLink = the link to a document  
  
## Discussion Board  
boardMakerID = UserID  
classID = ClassID  
boardTitle = Title to the board  
boardSubtitle = Subtitle to the board  
boardDueDate = Date = Due date of the board  
  
## Grade  
assignmentID = assignment ID attached  
graderID = who graded the assignment ID  
classID = Class ID  
gradePoints = How many points the assignment got  
gradeMaxPoints = Max assignment points  
  
## Group  
classID = Class ID  
leaderID = Group Creator ID  
groupID = Unique Group ID  
groupParticipants = [String] = Participants ID  
groupTitle = Name of the group  
assignmentID = assignment attached to it  
  
## GroupTask  
groupID = Group ID  
creatorID = Creator ID  
taskID = Unique Identifier for the task  
taskValue = The title of the task  
taskCreationDate = Date = The time that the task was created  
  
## GroupTaskCompletion  
taskID = Task ID  
groupID = Group ID  
creatorID = Who crossed out the task  
  
## GroupAttachments  
groupID = Group ID  
creatorID = Who attached the attachment to the group  
attachmentID = unique ID for the attachment  
attachmentLink = link for the attachment  
  
## GroupMessage  
groupID = Group ID  
creatorID = Message creator ID  
messageText = the body of the message  
messageDate = Date = the date that the message was created  
