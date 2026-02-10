from tflite_support.metadata_writers import image_classifier
from tflite_support.metadata_writers import writer_utils

MODEL_PATH = "assets/b1_aug.tflite"
LABELS_PATH = "assets/labels.txt"
OUTPUT_PATH = "assets/b1_aug_metadata.tflite"

writer = image_classifier.MetadataWriter.create_for_inference(
    writer_utils.load_file(MODEL_PATH),
    input_norm_mean=[127.5],
    input_norm_std=[127.5],
    label_file_paths=[LABELS_PATH],
)

populated_model = writer.populate()
writer_utils.save_file(populated_model, OUTPUT_PATH)
print("Saved:", OUTPUT_PATH)
