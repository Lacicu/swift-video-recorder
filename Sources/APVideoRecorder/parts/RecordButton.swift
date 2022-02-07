//
//  File.swift
//  
//
//  Created by Kyosuke Kawamura on 2022/02/07.
//
#if !os(macOS)
import UIKit

@objc internal protocol RecordButtonDelegate: NSObjectProtocol {
    @objc optional func start(_ sender: RecordButton)
    @objc optional func end(_ sender: RecordButton)
}

internal class RecordButton: UIView {
    
    enum RecordStatus {
        case tap
        case longPress
        case none
        case animate
    }
    
    private let size: CGFloat = 80
    private let selectedSize: CGFloat = 90
    
    weak var delegate: RecordButtonDelegate?
    
    private var status: RecordStatus = .none
    private var pressed: Bool = false {
        didSet {
            if (pressed == oldValue) {
                return
            }
            feedbackGenerator.impactOccurred()
            let previousStatus = status
            status = .animate
            if (pressed) {
                UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                    self.backgroundColor = .red
                }, completion: { _ in
                    self.status = previousStatus
                    self.delegate?.start?(self)
                })
            } else {
                UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                    self.backgroundColor = .clear
                }, completion: { _ in
                    self.status = .none
                    self.delegate?.end?(self)
                })
            }
        }
    }
    
    private var feedbackGenerator: UIImpactFeedbackGenerator {
        get {
            let generator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            return generator
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        frame.size = CGSize(width: selectedSize, height: selectedSize)
        backgroundColor = .clear
        layer.cornerRadius = selectedSize / 2
        
        let view = UIView(frame: CGRect(x: (selectedSize - size) / 2, y: (selectedSize - size) / 2, width: size, height: size))
        view.backgroundColor = .red
        view.layer.cornerRadius = size / 2
        addSubview(view)
        
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
        addGestureRecognizer(tapGesture)
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongGesture))
        addGestureRecognizer(longGesture)
    }
    
    @objc private func onTapGesture() {
        if (status == .none && !pressed) {
            status = .tap
            pressed = true
        } else if (status == .tap && pressed) {
            pressed = false
        }
    }
    
    @objc private func onLongGesture(_ sender: UIGestureRecognizer) {
        switch (sender.state) {
        case .possible:
            print("Long press possible")
        case .began:
            print("Long press began")
            if (status == .none && !pressed) {
                print("pressed = true")
                status = .longPress
                pressed = true
            }
        case .changed:
            print("Long press changed")
            return
        case .ended:
            print("Long press ended")
            if (status == .longPress && pressed) {
                print("pressed = false")
                pressed = false
            }
        case .cancelled:
            print("Long press cancelled")
        case .failed:
            print("Long press failed")
        @unknown default:
            fatalError()
        }
    }
    
}
#endif
