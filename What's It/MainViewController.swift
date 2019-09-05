//
//  MainViewController.swift
//  What's It
//
//  Created by Prabhunes on 7/8/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation
import Photos

@available(iOS 12.0, *)
@available(iOS 12.0, *)
class MainViewController: UIViewController, UIViewControllerWithGradientLayer, SupportingScoreDisplay, SupportingScoreUpdate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var clueButton: UIButton!
    @IBOutlet weak var guessButton: UIButton!
    @IBOutlet weak var newImageButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var waitLabel: UILabel!
    @IBOutlet weak var photoCreditLabel: UILabel!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var appIconCreditTextView: UITextView!
    @IBOutlet weak var newImageIconCreditTextView: UITextView!
    @IBOutlet weak var cameraIconCreditTextView: UITextView!
    @IBOutlet weak var infoButton: UIButton!

    private static var maxScore: Int { return 1000 }
    private static var minScore: Int { return 10 }
    private static var cluePoints: Int { return 25 }
    private static var guessPoints: Int { return 50 }
    private static var justTellMePoints: Int { return 100 }

    var gradientLayer: CAGradientLayer!
    var colorChangeAnimation: CABasicAnimation!

    var gradientTargetColors: [CGColor] = [UIColor.random.cgColor]
    var gradientTargetStartPoint: CGPoint = CGPoint.zero

    enum TransitionViewControllerTypes {
        case noViewController, clueViewController, guessViewController

        var name: String {

            switch self {
            case .noViewController:
                assert(false, "Name for view controller is not applicable")
                return ""
            case .clueViewController:
                return "ClueViewControllerID"
            case .guessViewController:
                return "GuessViewControllerID"
            }
        }
    }

    private var transitionViewControllerType = TransitionViewControllerTypes.noViewController

    private var numberOfLabelsSupported: Int { return 80 }
    private var predictionImageDimension: Int { return 416 }
    private var predictionConfidenceThreshold: Double { return 0.65 }
    private var minumumNumberOfUniqueLabels: Int { return 2 }
    private var maximumNumberOfImageRetries: Int { return 25 }

    private let fileName = "LabelClues"
    private var labels: [String] = []
    private var clueQuestions: [String] = []
    private var cluesDataArray: [[String]] = []
    private var cluesAnswersDataArray: [[String]] = []
    private var boundingEclipse: UIView?

    private var selectedLabel = ""
    private var selectedBoundingBoxIndex = 0
    private var selectedBoundingBoxRect: CGRect = CGRect.zero
    private var imageDownloadRetryCount = 0
    private var shouldContinueToAnimateLoadingLabel = false
    private var loadingAnimationLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 25))

    private var guessNodes: [GuessNode] = []
    private var clueNodes: [ClueNode] = []

    private var currentScore = MainViewController.maxScore
    private var optionalScoreUpdateTimer: Timer?
    private var hasObjectBeenGuessedCorrectly: Bool { return transitionViewControllerType == .noViewController &&
        optionalScoreUpdateTimer == nil }

    private var isImageFromSelfCamera = false
    private var photographerName = ""

    override func viewDidLoad() {

        func setupScrollView() {

            scrollView.minimumZoomScale = 0.5
            scrollView.maximumZoomScale = 6.0
            scrollView.contentSize = self.imageView.frame.size
            scrollView.delegate = self
        }

        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        setInfoViewText()

        createGradientLayer()
        setupScrollView()

        setupCluesData()

        getNewImageAndSetupTheImage()
    }

    override func viewWillAppear(_ animated: Bool) {

        scoreLabel.text = String(currentScore)
        hideInfoView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animateGradientLayer()

        print(transitionViewControllerType)
        if transitionViewControllerType != .noViewController {
            processReturnFromViewController(transitionViewControllerType)
        }

        transitionViewControllerType = .noViewController

        if hasObjectBeenGuessedCorrectly {
            hideButtonsForExistingImage()

            // The bounding boxes displayed are not that accurate
            // displaySelectedBoundingBoxWithAnimation()
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {

        return imageView;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onTouchUpInsideClueButton(_ sender: UIButton) {

        print("Need a Clue!")

        gradientLayer.removeAllAnimations()
        boundingEclipse?.removeFromSuperview()

        transitionViewControllerType = .clueViewController
        transitionToViewController(transitionViewControllerType)
    }

    @IBAction func onTouchUpInsideGuessButton(_ sender: UIButton) {

        print("Taking a Guess!")

        gradientLayer.removeAllAnimations()
        boundingEclipse?.removeFromSuperview()

        transitionViewControllerType = .guessViewController
        transitionToViewController(transitionViewControllerType)
    }

    @IBAction func onTouchUpInsideNewImageButton(_ sender: UIButton) {

        if hasObjectBeenGuessedCorrectly {
            boundingEclipse?.removeFromSuperview()
            getNewImageAndSetupTheImage()
            return
        }

        stopScheduleUpdateTimer()

        // Create the alert controller
        let alertController = UIAlertController(title: "", message: "Load a new image?", preferredStyle: .alert)

        // Create the actions
        let okAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) {
            UIAlertAction in
            NSLog("Yes Pressed")

            self.boundingEclipse?.removeFromSuperview()

            self.getNewImageAndSetupTheImage()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            NSLog("Cancel Pressed")

            self.scheduleScoreUpdateTimer() // Restart the timer since the action was canceled.
        }

        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func onTouchUpInsideCameraButton(_ sender: UIButton) {

        if hasObjectBeenGuessedCorrectly {
            boundingEclipse?.removeFromSuperview()
        }

        stopScheduleUpdateTimer()

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.presentCamera()
        }))

        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.presentPhotoGallery()
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(actionSheet, animated: true, completion: nil)
    }

    @IBAction func onTouchUpInsideInfoButton(_ sender: UIButton) {

        if isInfoViewHidden {
            showInfoView()
        } else {
            hideInfoView()
        }
    }

    private func transitionToViewController(_ transitionViewControllerType: TransitionViewControllerTypes) {

        switch transitionViewControllerType {
        case .clueViewController:
            presentClueViewController()
        case .guessViewController:
            presentGuessViewController()
        case .noViewController:
            assert(false, "Invalid call")
        }
    }

    private func presentGuessViewController() {

        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let guessViewController = storyBoard.instantiateViewController(withIdentifier: transitionViewControllerType.name) as! GuessViewController
        guessViewController.guessNodes = guessNodes
        guessViewController.selectedLabel = selectedLabel
        self.present(guessViewController, animated: true, completion: nil)
    }

    private func presentClueViewController() {

        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let clueViewController = storyBoard.instantiateViewController(withIdentifier: transitionViewControllerType.name) as! ClueViewController
        clueViewController.clueNodes = clueNodes
        self.present(clueViewController, animated: true, completion: nil)
    }

    private func processReturnFromViewController(_ transitionViewControllerType: TransitionViewControllerTypes) {

        switch transitionViewControllerType {
        case .clueViewController:
            processReturnFromClueViewController()
        case .guessViewController:
            processReturnFromGuessViewController()
        case .noViewController:
            assert(false, "Invalid call")
        }
    }

    private func processReturnFromClueViewController() {

        // No action presently
    }

    private func processReturnFromGuessViewController() {

        // No action presently
    }

    private func displaySelectedBoundingBoxWithAnimation() {

        let imageViewClippingRect = imageView.contentClippingRect
        print("imageViewClippingRect: \(imageViewClippingRect)")
        let predictedBoundingBoxRect = selectedBoundingBoxRect
        print("predictedBoundingBoxRect: \(predictedBoundingBoxRect)")
        let imageViewRect = imageViewRectScaledFrom(predictionUnitScaledRect: predictedBoundingBoxRect)
        print("imageViewRect: \(imageViewRect)")
        let imageViewRectOriginAdjusted = imageViewRectOriginAdjustedFrom(predictionImageRect: imageViewRect)
        print("imageViewRectOriginAdjusted: \(imageViewRectOriginAdjusted)")
        displayWithAnimation(rect: imageViewRectOriginAdjusted)
    }

    private func displayWithAnimation(rect: CGRect) {

        let width = rect.width // 140
        let height = rect.height // 200
        var xOffset = CGFloat(0)
        var yOffset = CGFloat(0)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { (context) in

            UIColor.white.setStroke()
            context.cgContext.strokeEllipse(in: CGRect(x: xOffset, y: yOffset, width: width, height: height))
            UIColor.red.setStroke()
            context.cgContext.strokeEllipse(in: CGRect(x: xOffset+1, y: yOffset+1, width: width-2, height: height-2))
            UIColor.white.setStroke()
            context.cgContext.strokeEllipse(in: CGRect(x: xOffset+2, y: yOffset+2, width: width-4, height: height-4))
        }

        let viewWidth = CGFloat(view.frame.width)
        let viewHeight = CGFloat(view.frame.height)
        let isOutOfViewX = Bool.random()
        if isOutOfViewX {
            let isEntryFromLeft = Bool.random()
            xOffset = isEntryFromLeft ? -width : viewWidth + width
            yOffset = CGFloat.random(in: -height...viewHeight + height)
        } else {
            let isEntryFromTop = Bool.random()
            xOffset = CGFloat.random(in: -width...viewWidth + width)
            yOffset = isEntryFromTop ? -height : viewHeight + height
        }

        let newImageView = UIImageView(image: image)
        newImageView.frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        view.addSubview(newImageView)
        boundingEclipse = newImageView

        UIView.animate(withDuration: 2.0, delay: 0, options: .curveEaseOut, animations: {

            newImageView.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)

        }, completion: { finished in

            UIView.animate(withDuration: 1.0,
                           delay: 0.0,
                           options: [.curveEaseInOut , .allowUserInteraction],
                           animations: {
                            newImageView.transform = CGAffineTransform(rotationAngle: .pi)
            },
                           completion: { finished in
                            print("Done with animate!")
            })

        })
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        onAnimationEnd(anim, finished: flag)
    }
}

extension MainViewController: UIScrollViewDelegate {

    func scrollViewDidZoom(_ scrollView: UIScrollView) {

        // Center the image if desired
//        let offsetX = CGFloat.maximum((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0.0)
//        let offsetY = CGFloat.maximum((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0.0)
//        imageView.center = CGPoint(x: (scrollView.contentSize.width * 0.5) + offsetX,
//                                   y: (scrollView.contentSize.height * 0.5) + offsetY)
//        imageView.center = CGPoint(x: scrollView.bounds.width/2,
//                                   y: scrollView.bounds.height/2)
    }
}

extension MainViewController {

    private func prediction(for image: UIImage?) -> PredictionResult? {

        let predictionModel = YOLOv3Int8LUT() // YOLOv3TinyInt8LUT YOLOv3Tiny YOLOv3TinyInt8LUT YOLOv3Int8LUT

        let dimension = predictionImageDimension
        guard let image = image, let cvPixelBuffer = image.pixelBuffer(width: dimension, height: dimension) else {
            return nil
        }

        do {
            let prediction = try predictionModel.prediction(image: cvPixelBuffer, iouThreshold: nil, confidenceThreshold: predictionConfidenceThreshold)
            print("\nprediction: \(prediction)\n")
            print("\nprediction.featureNames: \(prediction.featureNames)\n")
            print("\nprediction.confidence.shape: \(prediction.confidence.shape)\n")
            print("\nprediction.confidence: \(prediction.confidence)\n")
            print("\nprediction.coordinates.shape: \(prediction.coordinates.shape)\n")
            print("\nprediction.coordinates: \(prediction.coordinates)\n")
            let model = predictionModel.model
            print("\nmodel: \(model)\n")
            return PredictionResult(confidence: prediction.confidence, coordinates: prediction.coordinates)
        } catch {
            print("Unexpected error: \(error).")
            return nil
        }
    }

    private func uniqueLabels(in predictionResult: PredictionResult) -> [String] {

        var predictedLabels: [String] = []
        let confidence = predictionResult.confidence

        print("confidence.shape: \(confidence)")

        guard confidence.shape.count == 2 && confidence.strides.count == 2 else {
            assert(false, "Invalid prediction")
            return []
        }

        let numberOfBoundingBoxes = confidence.shape[0].intValue
        guard confidence.strides[1].intValue == 1 else { // Individual rows of confidence for each bounding box
            assert(false, "Invalid prediction")
            return []
        }
        guard numberOfBoundingBoxes > 0 else {
            print("No objects were found...")
            return []
        }

        let objectTypes = confidence.shape[1].intValue
        guard objectTypes == confidence.strides[0].intValue && objectTypes == numberOfLabelsSupported else {
            assert(false, "Invalid prediction...")
            return []
        }

        for boundingBoxIndex in 0..<numberOfBoundingBoxes {
            for labelConfidenceIndex in 0..<numberOfLabelsSupported {
                let confidenceDataIndex = (boundingBoxIndex * numberOfLabelsSupported) + labelConfidenceIndex
                let confidence = confidence[confidenceDataIndex].doubleValue
                if confidence >= predictionConfidenceThreshold {
                    predictedLabels.append(labels[labelConfidenceIndex])

                    print("\n\nDetected object at Box index\(boundingBoxIndex) of type: \(labels[labelConfidenceIndex]) with confidence \(confidence*100.0)%\n\n")
                }
            }
        }

        return predictedLabels.unique
    }

    private func label(forSelectedBoundingBoxIndex selectedBoundingBoxIndex: Int, withConfidenceMultiArray confidence: MLMultiArray) -> String {

        var selectedLabel = ""

        print("confidence.shape: \(confidence)")

        guard confidence.shape.count == 2 && confidence.strides.count == 2 else {
            assert(false, "Invalid prediction")
            return ""
        }

        let numberOfBoundingBoxes = confidence.shape[0].intValue
        guard confidence.strides[1].intValue == 1 else { // Individual rows of confidence for each bounding box
            assert(false, "Invalid prediction")
            return ""
        }
        guard numberOfBoundingBoxes > 0 else {
            assert(false, "No objects were found...")
            return ""
        }

        let objectTypes = confidence.shape[1].intValue
        guard objectTypes == confidence.strides[0].intValue && objectTypes == numberOfLabelsSupported else {
            assert(false, "Invalid prediction...")
            return ""
        }

        for boundingBoxIndex in 0..<numberOfBoundingBoxes {
            for labelConfidenceIndex in 0..<numberOfLabelsSupported {
                let confidenceDataIndex = (boundingBoxIndex * numberOfLabelsSupported) + labelConfidenceIndex
                let confidence = confidence[confidenceDataIndex].doubleValue
                if confidence >= predictionConfidenceThreshold {
                    if boundingBoxIndex == selectedBoundingBoxIndex {
                        selectedLabel = labels[labelConfidenceIndex]
                    }

                    print("\n\nDetected object at Box index\(boundingBoxIndex) of type: \(labels[labelConfidenceIndex]) with confidence \(confidence*100.0)%\n\n")
                }
            }
        }

        assert(!selectedLabel.isEmpty, "Invalid predection...")
        return selectedLabel
    }

    private func boundingBoxRects(forCoordinatesMultiArray coordinates: MLMultiArray) -> [CGRect]? {

        guard coordinates.shape.count == 2 && coordinates.strides.count == 2 else {
            assert(false, "Invalid prediction")
            return nil
        }

        let numOfBoundingBoxes = coordinates.shape[0].intValue
        guard coordinates.strides[1].intValue == 1 else { // Individual rows of origin & size for each bounding box
            assert(false, "Invalid prediction")
            return nil
        }
        guard numOfBoundingBoxes > 0 else {
            assert(false, "No objects were found...")
            return nil
        }

        let originAndSizeValues = coordinates.shape[1].intValue
        guard originAndSizeValues == 4 else {
            assert(false, "Invalid prediction...")
            return nil
        }

        var boundingBoxes: [CGRect] = []
        for boundinBoxIndex in 0..<numOfBoundingBoxes {
            let boundingBoxDataIndex = boundinBoxIndex * originAndSizeValues
            let originX = coordinates[boundingBoxDataIndex].doubleValue
            let originY = coordinates[boundingBoxDataIndex+1].doubleValue
            let boxWidth = coordinates[boundingBoxDataIndex+2].doubleValue
            let boxHeight = coordinates[boundingBoxDataIndex+3].doubleValue
            let rect = CGRect(x: originX, y: originY, width: boxWidth, height: boxHeight)
            boundingBoxes.append(rect)
        }

        guard !boundingBoxes.isEmpty else {
            assert(false, "Invalid image or prediction")
            return nil
        }

        return boundingBoxes
    }

    private func predictionImagePointFrom(predictionUnitScaledPoint point: CGPoint) -> CGPoint {
        let dimension = predictionImageDimension
        return CGPoint(x: point.x * CGFloat(dimension), y: point.y * CGFloat(dimension))
    }

    private func predictionImageRectScaledFrom(predictionUnitScaledRect rect: CGRect) -> CGRect {

        let dimension = CGFloat(predictionImageDimension)
        return rect.scaled(at: dimension)
    }

    private func imageViewRectScaledFrom(predictionImageRect rect: CGRect)  -> CGRect {
        let imageViewRect = imageView.contentClippingRect
        let imageViewDimension = imageViewRect.width < imageViewRect.height ? imageViewRect.width : imageViewRect.height
        let scale = CGFloat(imageViewDimension) / CGFloat(predictionImageDimension)
        return rect.scaled(at: scale)
    }

    private func imageViewRectScaledFrom(predictionUnitScaledRect rect: CGRect) -> CGRect {

        let imageViewRect = imageView.contentClippingRect
        let imageViewDimension = imageViewRect.width < imageViewRect.height ? imageViewRect.width : imageViewRect.height
        return rect.scaled(at: imageViewDimension)
    }

    private func imageViewRectOriginAdjustedFrom(predictionImageRect rect: CGRect)  -> CGRect {
        let imageViewRect = imageView.contentClippingRect
        let imageViewOrigin = imageViewRect.origin
        let imageViewDimension = imageViewRect.width < imageViewRect.height ? imageViewRect.width : imageViewRect.height
        let offsetX = imageViewOrigin.x + (imageViewRect.width - imageViewDimension)/2
        let offsetY = imageViewOrigin.y + (imageViewRect.height - imageViewDimension)/2
        return rect.offsetBy(dx: offsetX, dy: offsetY)
    }
}

extension MainViewController {

    private func labelClues(from file: String) throws -> (rowTitles: [String], columnTitles: [String], dataArray: [[String]], dataDictionary: [[String:String]]) {

        func readData(fromFile file: String) -> String! {

            guard let filepath = Bundle.main.path(forResource: file, ofType: "csv")
                else {
                    return nil
            }

            do {
                let contents = try String(contentsOfFile: filepath)
                return contents
            } catch {
                print ("File Read Error")
                return nil
            }
        }

        func cleanRows(from file: String) -> String {

            //use a uniform \n for end of lines.
            var cleanFile = file
            cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
            cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
            return cleanFile
        }

        func stringFields(forRow row:String, withDelimiter delimiter:String) -> [String] {

            return row.components(separatedBy: delimiter)
        }

        func convertCSV(file: String) -> (rowTitles: [String], columnTitles: [String], dataArray: [[String]], dataDictionary: [[String:String]]) {

            var dataDictionary: [[String:String]] = []
            var dataArray: [[String]] = []
            var rowTitles: [String] = []
            var columnTitles: [String] = []

            let rows = cleanRows(from: file).components(separatedBy: "\n")
            if rows.count > 0 {
                columnTitles = stringFields(forRow: rows.first!, withDelimiter:",")
                for row in rows {
                    if columnTitles.isEmpty {
                        break
                    }
                    let fields = stringFields(forRow: row, withDelimiter: ",")
                    if fields.count != columnTitles.count { continue }
                    dataArray.append(fields)
                    rowTitles.append(fields[0])
                    var dataRow = [String:String]()
                    for (index, field) in fields.enumerated() {
                        dataRow[columnTitles[index]] = field
                    }
                    dataDictionary += [dataRow]
                }
            } else {
                print("No data in file")
            }

            print(rowTitles)
            print(columnTitles)
            print(dataArray)
            return (rowTitles, columnTitles, dataArray, dataDictionary)
        }

        func printData(columnTitles: [String], dataDictionary data: [[String:String]]) {

            var tableString = ""
            var rowString = ""
            //print("data: \(data)")
            for row in data {
                rowString = ""
                for fieldName in columnTitles {
                    guard let field = row[fieldName] else {
                        print("field not found: \(fieldName)")
                        continue
                    }
                    rowString += field + "\t"
                }
                tableString += rowString + "\n"
            }

            print(tableString)
        }

        guard let fileContent =  readData(fromFile: file) else {
            throw AppError.csvError(message: "Error reading data from CSV file")
        }

        let fileDataTuple = convertCSV(file: fileContent)
        // printData(columnTitles: fileDataTuple.columnTitles, dataDictionary: fileDataTuple.dataDictionary)

        return fileDataTuple
    }
}

extension MainViewController {

    private func scheduleScoreUpdateTimer() {

        optionalScoreUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            print("Timer fired!")

            self.currentScore -= 1
            self.adjustCurrentScoreToMinimumAsNeeded()

            DispatchQueue.main.async {
                guard let topViewController = UIApplication.topViewController() as? SupportingScoreDisplay else {
                    return // This is possible when a confirmation message is displayed
                }
                topViewController.scoreLabel.text = String(self.currentScore)
            }
        }
    }

    private func stopScheduleUpdateTimer() {

        guard let scoreUpdateTimer = optionalScoreUpdateTimer else {
            return
        }

        scoreUpdateTimer.invalidate()
        optionalScoreUpdateTimer = nil
    }
}

extension MainViewController {

    private func setupCluesData() {

        do {
            let labelCluesDataTuple = try labelClues(from: fileName)

            labels = labelCluesDataTuple.rowTitles
            labels.removeFirst() // Remove the header row
            guessNodes = []
            for label in labels {
                guessNodes.append(GuessNode(name: label))
            }

            clueQuestions = labelCluesDataTuple.columnTitles
            clueQuestions.removeFirst() // Remove the header row
            cluesDataArray = labelCluesDataTuple.dataArray
            cluesAnswersDataArray = cluesDataArray
            cluesAnswersDataArray.removeFirst() // Remove the header row

            print("labels: \(labels)")
            print("clueQuestions: \(clueQuestions)")

        } catch AppError.csvError(let message) {
            print(message)
            return
        } catch {
            print("Unexpected app error.")
            return
        }
    }

    struct PredictionResult {
        var confidence: MLMultiArray = try! MLMultiArray(shape: [1], dataType: MLMultiArrayDataType.int32)
        var coordinates: MLMultiArray = try! MLMultiArray(shape: [1], dataType: MLMultiArrayDataType.int32)
    }

    private func getNewImageAndSetupTheImage() {

        hideButtonsAndScore()
        hidePhotoCreditInfo()
        imageView.image = UIImage()
        showWaitMessage()
        isImageFromSelfCamera = false

        if ReachabilityTest.isConnectedToNetwork() {
            print("Internet connection available")
            downloadImage()
        }
        else{
            print("No internet connection available")
            setupALocalImage()
        }
    }

    private func setupALocalImage() {

        let localImagesInfo = PexelsData.localImagesInfo
        let localImageInfo = localImagesInfo.randomElement()! // localImagesInfo.randomElement()! localImagesInfo[1]
        guard let image = UIImage(named: localImageInfo.imageName) else {
            assert(false, "The local image could not the loaded.")
            return
        }

        guard let predictionResult = prediction(for: image) else {
            assert(false, "Invalid prediction")
            return
        }

        let uniquePredictedLabels = uniqueLabels(in: predictionResult)

        assert(uniquePredictedLabels.count >= minumumNumberOfUniqueLabels, "Invalid number of unique labels.")

        photographerName = localImageInfo.photographer
        setupNewImage(image, with: predictionResult)
    }

    private func downloadImage() {

        func downloadRandomImageFrom(_ pexelsImages: [PexelsPhotos], with session: URLSession) {

            print("Downloading image with retry count: \(imageDownloadRetryCount)")

            let apiKey = Secret.apiKeyForPexels
            let imageIndex = Int.random(in: 0..<pexelsImages.count)
            let pexelsImage = pexelsImages[imageIndex]
            let urlString = pexelsImage.src.large
            print("responseObject - image#\(imageIndex) large URL: \(urlString)")

            guard let fileUrl = URL(string: urlString) else {
                assert(false, "Invalid URL")
                return
            }
            var request = URLRequest(url:fileUrl)
            request.setValue("image/jpeg" , forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "Authorization")

            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    assert(false, "Error downloading data: \(error)")
                    return
                }

                guard let data = data else {
                    assert(false, "Invalid data")
                    return
                }

                guard let image = UIImage(data: data) else {
                    assert(false, "Invalid prediction")
                    return
                }

                guard let predictionResult = self.prediction(for: image) else {
                    assert(false, "Invalid prediction")
                    return
                }

                let uniquePredictedLabels = self.uniqueLabels(in: predictionResult)

                if uniquePredictedLabels.count < self.minumumNumberOfUniqueLabels {

                    if self.imageDownloadRetryCount < self.maximumNumberOfImageRetries {

                        self.imageDownloadRetryCount += 1
                        downloadRandomImageFrom(pexelsImages, with: session)
                        return

                    } else {

                        DispatchQueue.main.async {
                            self.setupALocalImage()
                            return
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.photographerName = pexelsImage.photographer
                    self.setupNewImage(image, with: predictionResult)
                    return
                }
            }
            task.resume()
        }

        startAnimatingLoadingLabel()

        let apiKey = Secret.apiKeyForPexels
        let queryType = PexelsData.queryTypes.randomElement()!
        print("\nqueryType: \(queryType)\n")
        let urlString = PexelsData.baseUrl + queryType + PexelsData.queryDetailsUrlPart
        guard let fileUrl =  URL(string: urlString) else {
            assert(false, "Invalid URL")
            return
        }

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)

        var request = URLRequest(url:fileUrl)
        request.setValue("application/json; charset=utf-8" , forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                assert(false, "Error downloading data: \(error)")
                return
            }

            guard let data = data else {
                assert(false, "Invalid data")
                return
            }

            guard let jsonString = String(data: data, encoding: .utf8) else {
                assert(false, "Invalid jsonString")
                return
            }

            print(jsonString)
            let jsonData = jsonString.data(using: .utf8)!
            do {
                let responseObject = try JSONDecoder().decode(PexelsResponse.self, from: jsonData)
                print("responseObject: \(responseObject)")
                print("responseObject - photos count: \(responseObject.photos.count)")

                let images = responseObject.photos
                guard !images.isEmpty else {
                    self.setupALocalImage()
                    return
                }

                self.imageDownloadRetryCount = 0
                downloadRandomImageFrom(images, with: session)

            } catch {

                print("responseObject is not valid...")
                self.setupALocalImage()
                return
            }
        }
        task.resume()
    }

    private func setupNewImage(_ image: UIImage, with predictionResult: PredictionResult) {

        func setupHandlingForNewImage() {

            showButtonsAndScore()

            currentScore = MainViewController.maxScore
            scoreLabel.text = String(currentScore)
            scheduleScoreUpdateTimer()
        }

        stopAnimatingLoadingLabel()
        hideWaitMessage()
        imageView.image = image
        showPhotoCreditInfo()
        print("\nimage size: \(image.size)\n")
        print("\nimage aspect-fit size: \(imageView.contentClippingRect)\n")

        guard let boundingBoxes = boundingBoxRects(forCoordinatesMultiArray: predictionResult.coordinates) else
        {
            assert(false, "Invalid image or prediction")
            return
        }

        selectedBoundingBoxIndex = Int.random(in: 0..<boundingBoxes.count)
        print("selectedBoundingBoxIndex: \(selectedBoundingBoxIndex)")
        selectedBoundingBoxRect = boundingBoxes[selectedBoundingBoxIndex]
        print("selectedBoundingBoxRect:\(selectedBoundingBoxRect)")

        selectedLabel = label(forSelectedBoundingBoxIndex: selectedBoundingBoxIndex, withConfidenceMultiArray: predictionResult.confidence)
        print("***** selectedLabel: \(selectedLabel)")

        guard let selectedLabelIndex = labels.firstIndex(of: selectedLabel) else {
            assert(false, "Selected label could not be located within the clue data...")
            return
        }
        var clueAnswersForSelectedLabel = cluesAnswersDataArray[selectedLabelIndex]
        clueAnswersForSelectedLabel.removeFirst() // Remove the object type label
        print("Label: \(selectedLabel) - ClueAnswers: \(clueAnswersForSelectedLabel)")

        guard clueQuestions.count == clueAnswersForSelectedLabel.count else {
            assert(false, "Invalid clue data for the selected label...")
            return
        }

        clueNodes = []
        for index in 0..<clueQuestions.count {
            let clueNode = ClueNode(name: clueQuestions[index], answer: clueAnswersForSelectedLabel[index])
            clueNodes.append(clueNode)
        }

        for guessNode in guessNodes {
            guessNode.isSelected = false
        }

        setupHandlingForNewImage()
    }

    func startAnimatingLoadingLabel() {

        loadingAnimationLabel.alpha = 0
        view.addSubview(loadingAnimationLabel)

        shouldContinueToAnimateLoadingLabel = true
        animateLoadingLabel()
    }

    func stopAnimatingLoadingLabel() {

        shouldContinueToAnimateLoadingLabel = false
        DispatchQueue.main.async {
            self.loadingAnimationLabel.removeFromSuperview()
        }
    }

    func animateLoadingLabel() {

        DispatchQueue.main.async {
            if !self.shouldContinueToAnimateLoadingLabel {
                self.loadingAnimationLabel.alpha = 0
                return
            }

            var labelX: CGFloat { return CGFloat.random(in: 0..<self.view.frame.width-self.loadingAnimationLabel.frame.width) }
            var labelY: CGFloat { return CGFloat.random(in: 0..<self.view.frame.height-self.loadingAnimationLabel.frame.height) }
            var isLabelInUpperHalf: Bool { return self.loadingAnimationLabel.frame.origin.y < self.view.frame.height/2 }

            self.loadingAnimationLabel.frame.origin = CGPoint(x: labelX, y: labelY)
            self.loadingAnimationLabel.alpha = 0
            self.loadingAnimationLabel.text = self.labels.randomElement()?.capitalized
            self.loadingAnimationLabel.textColor = isLabelInUpperHalf ? UIColor.darkRandom : UIColor.lightRandom

            self.loadingAnimationLabel.fadeIn(completion: {
                (finished: Bool) -> Void in

                self.loadingAnimationLabel.fadeOut(completion: {
                    (finished: Bool) -> Void in

                    self.animateLoadingLabel()
                })
            })
        }
    }

    func hideButtonsForExistingImage() {
        clueButton.isHidden = true
        guessButton.isHidden = true
    }

    func hideButtonsAndScore() {
        clueButton.isHidden = true
        guessButton.isHidden = true
        newImageButton.isHidden = true
        cameraButton.isHidden = true
        scoreLabel.isHidden = true
        infoButton.isHidden = true
    }

    func showButtonsAndScore() {
        clueButton.isHidden = false
        guessButton.isHidden = false
        newImageButton.isHidden = false
        cameraButton.isHidden = false
        scoreLabel.isHidden = false
        infoButton.isHidden = false
    }

    func showWaitMessage() {
        waitLabel.isHidden = false
    }

    func hideWaitMessage() {
        waitLabel.isHidden = true
    }

    func showPhotoCreditInfo() {
        guard !isImageFromSelfCamera else {
            return
        }
        photoCreditLabel.text = "Photo Credit: Pexels" + (!photographerName.isEmpty ? "\nBy: \(photographerName)" : "")
        photoCreditLabel.fadeIn(duration: 2, targetAlpha: 0.5)
    }

    func hidePhotoCreditInfo() {
        photoCreditLabel.alpha = 0
        photographerName = ""
    }
}

extension MainViewController {

    private func adjustCurrentScoreToMinimumAsNeeded() {

        if currentScore < MainViewController.minScore {
            currentScore = MainViewController.minScore
        }
    }

    internal func updateCurrentScoreForTakingAGuess() {

        currentScore -= MainViewController.guessPoints
        adjustCurrentScoreToMinimumAsNeeded()
    }

    internal func updateCurrentScoreForGettingAClue() {

        currentScore -= MainViewController.cluePoints
        adjustCurrentScoreToMinimumAsNeeded()
    }

    internal func updateCurrentScoreForJustTellMeOption() {

        currentScore -= MainViewController.justTellMePoints
        adjustCurrentScoreToMinimumAsNeeded()
    }

    internal func stopCurrentScoreUpdate() {

        stopScheduleUpdateTimer()
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func presentCameraOrPhotoGallery(shouldDisplayCamera: Bool) {

        let sourceType: UIImagePickerController.SourceType = shouldDisplayCamera ? .camera : .photoLibrary
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            displayMessage("Camera/photo gallery is not accessible...")
            if !self.hasObjectBeenGuessedCorrectly {
                self.scheduleScoreUpdateTimer() // Restart the timer
            }
            return
        }

        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self;
        imagePickerController.sourceType = sourceType
        present(imagePickerController, animated: true, completion: nil)
    }

    private func presentCamera() {

        guard AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    self.presentCamera() // Try to access the camera again
                } else {
                    self.displayMessage("Camera could not be accessed...")
                    if !self.hasObjectBeenGuessedCorrectly {
                        self.scheduleScoreUpdateTimer() // Restart the timer
                    }
                }
            })
            return
        }

        presentCameraOrPhotoGallery(shouldDisplayCamera: true)
    }

    func presentPhotoGallery() {

        guard PHPhotoLibrary.authorizationStatus() ==  .authorized else {
            PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
                if status == .authorized {
                    self.presentPhotoGallery()
                } else {
                    self.displayMessage("The photo gallery could not be accessed...")
                    if !self.hasObjectBeenGuessedCorrectly {
                        self.scheduleScoreUpdateTimer() // Restart the timer
                    }
                }
            }
            return
        }

        presentCameraOrPhotoGallery(shouldDisplayCamera: false)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let image = info[.originalImage] as? UIImage else {

            displayMessage("Error getting the image from the camera.")
            if !self.hasObjectBeenGuessedCorrectly {
                self.scheduleScoreUpdateTimer() // Restart the timer
            }
            return
        }

        picker.dismiss(animated: true, completion: nil)

        guard let predictionResult = self.prediction(for: image) else {
            assert(false, "Invalid prediction")
            if !self.hasObjectBeenGuessedCorrectly {
                self.scheduleScoreUpdateTimer() // Restart the timer
            }
            return
        }

        let uniquePredictedLabels = self.uniqueLabels(in: predictionResult)

        if uniquePredictedLabels.count < self.minumumNumberOfUniqueLabels {

            displayMessage("The image doesn't have minimum number of supported objects.")
            if !self.hasObjectBeenGuessedCorrectly {
                self.scheduleScoreUpdateTimer() // Restart the timer
            }
            return
        }

        isImageFromSelfCamera = true
        setupNewImage(image, with: predictionResult)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

        picker.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController {

    @IBAction func handleTapOnView(_ gestureRecognizer : UITapGestureRecognizer ) {

        guard gestureRecognizer.view != nil else { return }

        print("Tap detected")

        if isInfoViewDisplayed {
            hideInfoView()
        }
    }

    private func hideInfoView() {
        infoView.alpha = 0
    }

    private func showInfoView() {
        infoView.alpha = 0.90
    }

    private var isInfoViewHidden: Bool { return infoView.alpha == 0 }

    private var isInfoViewDisplayed: Bool { return infoView.alpha != 0 }

    private func setInfoViewText() {

        enum IconLicenseType {
            case flaticon, creativeCommons
        }

        func creditStringforContributor(name: String, link: String, licenseType: IconLicenseType) -> NSAttributedString {

            var creditString = ""
            let flatIconTitle = "www.flaticon.com"
            let flatIconLink = "https://www.flaticon.com/"
            let creativeCommonTitle = "CC 3.0 BY"
            let creativeCommonLink = "http://creativecommons.org/licenses/by/3.0/"

            switch licenseType {
            case .flaticon:
                creditString = "Icon made by \(name) from \(flatIconTitle)"
            case .creativeCommons:
                creditString = "Icon made by \(name) from \(flatIconTitle) is licensed by \(creativeCommonTitle)"
            }

            let creditAttributedString = NSMutableAttributedString(string: creditString)
            creditAttributedString.addAttribute(.link, value: link, range: (creditString as NSString).range(of: name))
            creditAttributedString.addAttribute(.link, value: flatIconLink, range: (creditString as NSString).range(of: flatIconTitle))
            if licenseType == .creativeCommons {
                creditAttributedString.addAttribute(.link, value: creativeCommonLink, range: (creditString as NSString).range(of: creativeCommonTitle))
            }
            creditAttributedString.addAttribute(.font, value: UIFont(name: "Helvetica Neue", size: 12.0)!, range: creditString.nsRange)
            creditAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: creditString.nsRange)
            return creditAttributedString
        }

        let linkAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.underlineColor: UIColor.white,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let appIconCreditString = creditStringforContributor(name: "Freepik", link: "https://www.flaticon.com/authors/freepik", licenseType: .flaticon)
        appIconCreditTextView.attributedText = appIconCreditString
        appIconCreditTextView.linkTextAttributes = linkAttributes

        let newImageIconCreditString = creditStringforContributor(name: "Smashicons", link: "https://www.flaticon.com/authors/smashicons", licenseType: .creativeCommons)
        newImageIconCreditTextView.attributedText = newImageIconCreditString
        newImageIconCreditTextView.linkTextAttributes = linkAttributes

        let cameraIconCreditString = creditStringforContributor(name: "Payungkead", link: "https://www.flaticon.com/authors/payungkead", licenseType: .creativeCommons)
        cameraIconCreditTextView.attributedText = cameraIconCreditString
        cameraIconCreditTextView.linkTextAttributes = linkAttributes
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        UIApplication.shared.open(URL)
        return false
    }
}
