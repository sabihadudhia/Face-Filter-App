import UIKit
import ARKit
import SceneKit
import Vision
import CoreML

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Properties
    var sceneView: ARSCNView!
    var ciContext: CIContext!
    var agingImageView: UIImageView!
    
    // Filter nodes
    var hatNode: SCNNode?
    var glassesNode: SCNNode?
    
    // Filter state
    var currentFilter = 0
    let filterNames = ["🎩  Accessories", "😊  Expression", "🔮  Age Estimator", "👴  1900's filter"]
    var isFrontCamera = true
    var frameCounter = 0
    
    // MARK: - UI Elements
    var filterNameLabel: UILabel!
    var expressionLabel: UILabel!
    var ageLabel: UILabel!
    var prevButton: UIButton!
    var nextButton: UIButton!
    var flipButton: UIButton!
    var filterIndicatorStack: UIStackView!
    var dots: [UIView] = []
    
    // Photo Saving
    var captureButton: UIButton!
    var flashView: UIView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupUI()
        
        ciContext = CIContext()
        
        agingImageView = UIImageView(frame: view.bounds)
        agingImageView.contentMode = .scaleAspectFill
        agingImageView.isHidden = true
        agingImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(agingImageView, aboveSubview: sceneView)
        
        // Bring UI elements above aging view
        view.bringSubviewToFront(filterNameLabel.superview!)
        view.bringSubviewToFront(expressionLabel)
        view.bringSubviewToFront(ageLabel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession(front: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - AR Setup
    func setupARView() {
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = true  // ADD THIS LINE
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sceneView)
    }
    
    func startSession(front: Bool) {
        if front {
            guard ARFaceTrackingConfiguration.isSupported else { return }
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        } else {
            let config = ARWorldTrackingConfiguration()
            config.isLightEstimationEnabled = true
            sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let topBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        topBlur.layer.cornerRadius = 22
        topBlur.clipsToBounds = true
        topBlur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBlur)
        
        filterNameLabel = UILabel()
        filterNameLabel.text = filterNames[currentFilter]
        filterNameLabel.textColor = .white
        filterNameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        filterNameLabel.textAlignment = .center
        filterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        topBlur.contentView.addSubview(filterNameLabel)
        
        NSLayoutConstraint.activate([
            topBlur.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topBlur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topBlur.widthAnchor.constraint(equalToConstant: 220),
            topBlur.heightAnchor.constraint(equalToConstant: 44),
            filterNameLabel.centerXAnchor.constraint(equalTo: topBlur.centerXAnchor),
            filterNameLabel.centerYAnchor.constraint(equalTo: topBlur.centerYAnchor)
        ])
        
        expressionLabel = UILabel()
        expressionLabel.textColor = .white
        expressionLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        expressionLabel.textAlignment = .center
        expressionLabel.isHidden = true
        expressionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(expressionLabel)
        
        NSLayoutConstraint.activate([
            expressionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            expressionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            expressionLabel.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        ageLabel = UILabel()
        ageLabel.textColor = .white
        ageLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        ageLabel.textAlignment = .center
        ageLabel.isHidden = true
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ageLabel)
        
        NSLayoutConstraint.activate([
            ageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            ageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ageLabel.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        let bottomBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        bottomBlur.layer.cornerRadius = 30
        bottomBlur.clipsToBounds = true
        bottomBlur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBlur)
        
        NSLayoutConstraint.activate([
            bottomBlur.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            bottomBlur.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomBlur.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            bottomBlur.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        prevButton = makeIconButton(systemName: "chevron.left")
        prevButton.addTarget(self, action: #selector(prevFilter), for: .touchUpInside)
        bottomBlur.contentView.addSubview(prevButton)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        
        nextButton = makeIconButton(systemName: "chevron.right")
        nextButton.addTarget(self, action: #selector(nextFilter), for: .touchUpInside)
        bottomBlur.contentView.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        
        flipButton = makeIconButton(systemName: "arrow.triangle.2.circlepath.camera")
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        bottomBlur.contentView.addSubview(flipButton)
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        
        filterIndicatorStack = UIStackView()
        filterIndicatorStack.axis = .horizontal
        filterIndicatorStack.spacing = 8
        filterIndicatorStack.alignment = .center
        filterIndicatorStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBlur.contentView.addSubview(filterIndicatorStack)
        
        for i in 0..<filterNames.count {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.backgroundColor = i == 0 ? .white : UIColor.white.withAlphaComponent(0.3)
            let size: CGFloat = i == 0 ? 8 : 6
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: size),
                dot.heightAnchor.constraint(equalToConstant: size)
            ])
            filterIndicatorStack.addArrangedSubview(dot)
            dots.append(dot)
        }
        
        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: bottomBlur.contentView.leadingAnchor, constant: 20),
            prevButton.centerYAnchor.constraint(equalTo: bottomBlur.contentView.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            prevButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.trailingAnchor.constraint(equalTo: flipButton.leadingAnchor, constant: -12),
            nextButton.centerYAnchor.constraint(equalTo: bottomBlur.contentView.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            flipButton.trailingAnchor.constraint(equalTo: bottomBlur.contentView.trailingAnchor, constant: -20),
            flipButton.centerYAnchor.constraint(equalTo: bottomBlur.contentView.centerYAnchor),
            flipButton.widthAnchor.constraint(equalToConstant: 44),
            flipButton.heightAnchor.constraint(equalToConstant: 44),
            
            filterIndicatorStack.centerXAnchor.constraint(equalTo: bottomBlur.contentView.centerXAnchor),
            filterIndicatorStack.centerYAnchor.constraint(equalTo: bottomBlur.contentView.centerYAnchor)
        ])
        
        
        // Capture button — centred, larger, above the bottom bar
        captureButton = UIButton()
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 32
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -112),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 64),
            captureButton.heightAnchor.constraint(equalToConstant: 64)
        ])

        // White flash overlay for capture feedback
        flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        flashView.isUserInteractionEnabled = false
        flashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flashView)


    }
    
    func makeIconButton(systemName: String) -> UIButton {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 22
        return button
    }
    
    @objc func capturePhoto() {
        
        // Flash effect
        UIView.animate(withDuration: 0.1, animations: {
            self.flashView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.flashView.alpha = 0
            }
        }
        
        // Button press feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.captureButton.transform = .identity
            }
        }
        
        // Capture whatever is currently on screen — AR view + any overlays
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let screenshot = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Save to Photos app
        UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(savedPhotoCallback), nil)
    }

    @objc func savedPhotoCallback(_ image: UIImage,
                                  didFinishSavingWithError error: Error?,
                                  contextInfo: UnsafeRawPointer) {
        
        DispatchQueue.main.async {
            let message = error == nil ? "Saved ✓" : "Failed to save"
            
            let toast = UILabel()
            toast.text = message
            toast.textColor = .white
            toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            toast.textAlignment = .center
            toast.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            toast.layer.cornerRadius = 16
            toast.clipsToBounds = true
            toast.alpha = 0
            toast.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(toast)
            
            NSLayoutConstraint.activate([
                toast.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                toast.bottomAnchor.constraint(equalTo: self.captureButton.topAnchor, constant: -20),
                toast.widthAnchor.constraint(equalToConstant: 100),
                toast.heightAnchor.constraint(equalToConstant: 32)
            ])
            
            UIView.animate(withDuration: 0.2, animations: {
                toast.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 1.0, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }

    
    // MARK: - Filter Switching
    @objc func prevFilter() {
        currentFilter = (currentFilter - 1 + filterNames.count) % filterNames.count
        animateFilterChange()
    }
    
    @objc func nextFilter() {
        currentFilter = (currentFilter + 1) % filterNames.count
        animateFilterChange()
    }
    
    @objc func flipCamera() {
        isFrontCamera.toggle()
        UIView.transition(with: sceneView, duration: 0.4,
                         options: .transitionFlipFromLeft) {
            self.startSession(front: self.isFrontCamera)
        }
        flipButton.tintColor = isFrontCamera ? .white : .systemYellow
        updateFilterVisibility()
    }
    
    func animateFilterChange() {
        UIView.animate(withDuration: 0.15, animations: {
            self.filterNameLabel.alpha = 0
            self.filterNameLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            self.filterNameLabel.text = self.filterNames[self.currentFilter]
            UIView.animate(withDuration: 0.2, delay: 0,
                          usingSpringWithDamping: 0.7,
                          initialSpringVelocity: 0.5) {
                self.filterNameLabel.alpha = 1
                self.filterNameLabel.transform = .identity
            }
        }
        
        for (i, dot) in dots.enumerated() {
            UIView.animate(withDuration: 0.2) {
                dot.backgroundColor = i == self.currentFilter
                    ? .white : UIColor.white.withAlphaComponent(0.3)
                let size: CGFloat = i == self.currentFilter ? 8 : 6
                dot.layer.cornerRadius = size / 2
            }
        }
        
        updateFilterVisibility()
    }
    
    func updateFilterVisibility() {
        let front = isFrontCamera
        hatNode?.isHidden        = !front || currentFilter != 0
        glassesNode?.isHidden    = !front || currentFilter != 0
        expressionLabel.isHidden = currentFilter != 1
        ageLabel.isHidden        = currentFilter != 2
        agingImageView.isHidden  = currentFilter != 3
        
        // Clear aging image when switching away
        if currentFilter != 3 {
            agingImageView.image = nil
        }
    }
    
    // MARK: - Accessory Node
    func createAccessoryNode(imageName: String,
                             width: Float,
                             height: Float) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        plane.firstMaterial?.diffuse.contents = UIImage(named: imageName)
        plane.firstMaterial?.isDoubleSided = true
        return SCNNode(geometry: plane)
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer,
                  nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let device = sceneView.device,
              anchor is ARFaceAnchor
        else { return nil }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)!
        let faceNode = SCNNode(geometry: faceGeometry)
        faceGeometry.firstMaterial?.colorBufferWriteMask = []
        
        // Filter 1 — accessories
        let hat = createAccessoryNode(imageName: "hat", width: 0.25, height: 0.20)
        hat.position = SCNVector3(0, 0.20, -0.05)
        hatNode = hat
        faceNode.addChildNode(hat)
        
        let glasses = createAccessoryNode(imageName: "glasses", width: 0.14, height: 0.08)
        glasses.position = SCNVector3(0, 0.025, 0.06)
        glassesNode = glasses
        faceNode.addChildNode(glasses)
        
        DispatchQueue.main.async { self.updateFilterVisibility() }
        
        return faceNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode,
                  for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry
        else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        if currentFilter == 1 {
            detectExpression(from: faceAnchor.blendShapes)
        }
        
        if currentFilter == 2 {
            frameCounter += 1
            if frameCounter % 30 == 0 {
                if let pixelBuffer = sceneView.session.currentFrame?.capturedImage {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.estimateAge(from: pixelBuffer)
                    }
                }
            }
        }
        
        if currentFilter == 3 {
            if let pixelBuffer = sceneView.session.currentFrame?.capturedImage {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.applyAgingCIFilter(pixelBuffer: pixelBuffer)
                }
            }
        }
    }
    
    // MARK: - Filter 2: Expression
    func detectExpression(from blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        let smileLeft  = blendShapes[.mouthSmileLeft]?.floatValue  ?? 0
        let smileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0
        let jawOpen    = blendShapes[.jawOpen]?.floatValue         ?? 0
        let browUp     = blendShapes[.browInnerUp]?.floatValue     ?? 0
        let browDown   = blendShapes[.browDownLeft]?.floatValue    ?? 0
        let smileAvg   = (smileLeft + smileRight) / 2
        
        var expression = ""
        var colour = UIColor.white
        
        if smileAvg > 0.35 {
            expression = "Happy 😊"
            colour = .systemYellow
        } else if jawOpen > 0.4 && browUp > 0.3 {
            expression = "Surprised 😮"
            colour = .systemBlue
        } else if browDown > 0.4 {
            expression = "Angry 😠"
            colour = .systemRed
        } else {
            expression = "Neutral 😐"
            colour = .white
        }
        
        DispatchQueue.main.async {
            self.expressionLabel.text = expression
            self.expressionLabel.textColor = colour
        }
    }
    
    // MARK: - Filter 3: Age Estimator
    func estimateAge(from pixelBuffer: CVPixelBuffer) {
        guard let model = try? VNCoreMLModel(
            for: AgeClassifier(configuration: MLModelConfiguration()).model)
        else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first
            else { return }
            
            let confidence = Int(top.confidence * 100)
            let display: String
            switch top.identifier {
            case "0_15":    display = "Age: 0–15 🧒  (\(confidence)%)"
            case "16_25":   display = "Age: 16–25 🧑  (\(confidence)%)"
            case "26_35":   display = "Age: 26–35 👨  (\(confidence)%)"
            case "36_50":   display = "Age: 36–50 🧔  (\(confidence)%)"
            case "51_65":   display = "Age: 51–65 👴  (\(confidence)%)"
            case "66_plus": display = "Age: 66+ 👴  (\(confidence)%)"
            default:        display = "Age: \(top.identifier) (\(confidence)%)"
            }
            
            DispatchQueue.main.async {
                self?.ageLabel.text = display
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored)
        try? handler.perform([request])
    }
    
    // MARK: - Filter 4: Make Me 95 (CIFilter aging effect)
    func applyAgingCIFilter(pixelBuffer: CVPixelBuffer) {
        
        var image = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        
        // Step 1 — Desaturate and increase contrast
        let colourControls = CIFilter(name: "CIColorControls")!
        colourControls.setValue(image, forKey: kCIInputImageKey)
        colourControls.setValue(0.20,  forKey: "inputSaturation")
        colourControls.setValue(0.03,  forKey: "inputBrightness")
        colourControls.setValue(1.20,  forKey: "inputContrast")
        if let out = colourControls.outputImage { image = out }
        
        // Step 2 — Warm aged skin tone
        let colourMatrix = CIFilter(name: "CIColorMatrix")!
        colourMatrix.setValue(image, forKey: kCIInputImageKey)
        colourMatrix.setValue(CIVector(x: 1.14, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colourMatrix.setValue(CIVector(x: 0, y: 1.04, z: 0, w: 0), forKey: "inputGVector")
        colourMatrix.setValue(CIVector(x: 0, y: 0, z: 0.80, w: 0), forKey: "inputBVector")
        if let out = colourMatrix.outputImage { image = out }
        
        // Step 3 — Sharpen to emphasise skin texture and fine lines
        let sharpen = CIFilter(name: "CIUnsharpMask")!
        sharpen.setValue(image, forKey: kCIInputImageKey)
        sharpen.setValue(3.0,  forKey: "inputRadius")
        sharpen.setValue(0.7,  forKey: "inputIntensity")
        if let out = sharpen.outputImage { image = out }
        
        // Step 4 — Vignette to darken edges
        let vignette = CIFilter(name: "CIVignette")!
        vignette.setValue(image, forKey: kCIInputImageKey)
        vignette.setValue(2.0,  forKey: "inputIntensity")
        vignette.setValue(0.55, forKey: "inputRadius")
        if let out = vignette.outputImage { image = out }
        
        // Step 5 — Slight blur on smooth areas to simulate aged skin texture loss
        let bloom = CIFilter(name: "CIBloom")!
        bloom.setValue(image, forKey: kCIInputImageKey)
        bloom.setValue(3.0,  forKey: "inputRadius")
        bloom.setValue(0.3,  forKey: "inputIntensity")
        if let out = bloom.outputImage { image = out }
        
        // Render
        guard let cgImage = ciContext.createCGImage(image, from: image.extent)
        else { return }
        
        let result = UIImage(cgImage: cgImage)
        
        DispatchQueue.main.async {
            self.agingImageView.image = result
        }
    }
}
