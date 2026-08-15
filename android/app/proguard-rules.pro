# ONNX Runtime JNI needs its classes preserved from R8 minification.
# Without this rule release builds crash with:
#   JNI DETECTED ERROR IN APPLICATION: java_class == null
#   from ai.onnxruntime.OrtSession.run(...)
-keep class ai.onnxruntime.** { *; }
