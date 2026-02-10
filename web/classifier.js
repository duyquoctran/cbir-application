import {
  FilesetResolver,
  ImageClassifier,
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/vision_bundle.mjs";

let classifierPromise = null;

async function getClassifier() {
  if (classifierPromise) return classifierPromise;

  classifierPromise = (async () => {
    const fileset = await FilesetResolver.forVisionTasks(
      "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
    );

    return ImageClassifier.createFromOptions(fileset, {
      baseOptions: {
        modelAssetPath: "assets/assets/b1_aug.tflite",
      },
      maxResults: 1,
    });
  })();

  return classifierPromise;
}

async function loadImage(dataUrl) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = (err) => reject(err);
    img.src = dataUrl;
  });
}

window.tfliteClassify = async function (dataUrl) {
  const classifier = await getClassifier();
  const image = await loadImage(dataUrl);
  const results = classifier.classify(image);

  if (!results || !results.classifications || results.classifications.length === 0) {
    return { label: "unknown", confidence: 0.0 };
  }

  const top = results.classifications[0].categories[0];
  return { label: top.categoryName, confidence: top.score };
};
