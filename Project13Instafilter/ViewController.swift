//
//  ViewController.swift
//  Project13Instafilter
//
//  Created by Tai Chin Huang on 2021/9/9.
//

import UIKit
// import CoreImage framework to use CIFilter
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var intensity: UISlider!
    @IBOutlet weak var radius: UISlider!
    @IBOutlet weak var scale: UISlider!
    @IBOutlet weak var changeFilter: UIButton!
    // containing image that user selected
    var currentImage: UIImage!
    // core image component that rendering image
    var context: CIContext!
    // create filter that user has activated
    var currentFilter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Instafilter"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        context = CIContext()
        currentFilter = CIFilter(name: "CISepiaTone")
        
        changeFilter.titleLabel?.adjustsFontSizeToFitWidth = true
        changeFilter.titleLabel?.minimumScaleFactor = 0.5
        
        resetUI()
    }
    
    @objc func importPicture() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    //MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        currentImage = image
        // core image版的UIImage，任何要接受filter的圖片都要先轉換成CIImage
        let beginImage = CIImage(image: currentImage)
        // key for CIImage to use as an input image，先載入圖片
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        applyProcessing()
        
        dismiss(animated: true, completion: nil)
    }
    
    func applyProcessing() {
        // 從currentFilter取得他所有的inputKeys(有哪些調特效的濾鏡)
        let inputKeys = currentFilter.inputKeys
        // 然後分類要調整的內容
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey)
            intensity.isUserInteractionEnabled = true
            intensity.minimumTrackTintColor = .blue
            radius.isUserInteractionEnabled = false
            radius.minimumTrackTintColor = .red
            scale.isUserInteractionEnabled = false
            scale.minimumTrackTintColor = .red
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(radius.value * 200, forKey: kCIInputRadiusKey)
            intensity.isUserInteractionEnabled = false
            intensity.minimumTrackTintColor = .red
            radius.isUserInteractionEnabled = true
            radius.minimumTrackTintColor = .blue
            scale.isUserInteractionEnabled = false
            scale.minimumTrackTintColor = .red
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(scale.value * 10, forKey: kCIInputScaleKey)
            intensity.isUserInteractionEnabled = false
            intensity.minimumTrackTintColor = .red
            radius.isUserInteractionEnabled = false
            radius.minimumTrackTintColor = .red
            scale.isUserInteractionEnabled = true
            scale.minimumTrackTintColor = .blue
        }
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        if let cgImage = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgImage)
            imageView.image = processedImage
        }
    }
    @IBAction func intensityChange(_ sender: UISlider) {
        applyProcessing()
    }
    @IBAction func radiusChange(_ sender: UISlider) {
        applyProcessing()
    }
    @IBAction func scaleChange(_ sender: UISlider) {
        applyProcessing()
    }
    
    // 選擇濾鏡後讓currentFilter更改成對應的濾鏡，然後再跑一次applyProcessing()
    @IBAction func changeFilter(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
        
        let filterTitles = ["CIBumpDistortion", "CIGaussianBlur", "CIPixellate", "CISepiaTone", "CITwirlDistortion", "CIUnsharpMask", "CIVignette"]
        for filterTitle in filterTitles {
            alertController.addAction(UIAlertAction(title: filterTitle, style: .default, handler: setFilter))
        }
        
        present(alertController, animated: true)
    }
    
    func setFilter(_ action: UIAlertAction) {
        guard currentImage != nil else { return }
        // 從action的title來輸入對應的濾鏡名稱
        guard let actionTitle = action.title else { return }
        currentFilter = CIFilter(name: actionTitle)
        let beginImage = CIImage(image: currentImage)
        // 重選filter類型都要重新導入一次kCIInputImageKey
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        changeFilter.setTitle(actionTitle, for: .normal)
        applyProcessing()
    }
    
    @IBAction func save(_ sender: UIButton) {
        guard let image = imageView.image else {
            let alertController = UIAlertController(title: "Error", message: "No photo to save!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            present(alertController, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Saved!", message: "Your image have been saved into photo album", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(okAction)
            
            present(alertController, animated: true) {
                self.resetUI()
            }
        }
    }
    func resetUI() {
        intensity.isUserInteractionEnabled = false
        intensity.minimumTrackTintColor = .red
        intensity.value = 0.5
        radius.isUserInteractionEnabled = false
        radius.minimumTrackTintColor = .red
        radius.value = 0.5
        scale.isUserInteractionEnabled = false
        scale.minimumTrackTintColor = .red
        scale.value = 0.5
    }
}

