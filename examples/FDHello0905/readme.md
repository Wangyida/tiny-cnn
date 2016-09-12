# This is a simple demo for building IOS app based on tiny_dnn
1. Create a new project
2. Convert ```viewcontroller.m``` to ```viewcontroller.mm```(.mm is used for mixture porgramming of c++ and objc, we treat viewcontroller all in .mm style)
3. Import opencv2.framework under Libs directory, click right key button on project ->  add Files to "project" -> choose directory where opencv2.framework exists, choose -> Add 
4. Import libProtobufLib.a (From official website, compile it into library for mixture programming of c++ and objc)
5. As for build settings of Xcode for project, you can do this: -> search path -> header search paths -> add dir(protobuf)/src
