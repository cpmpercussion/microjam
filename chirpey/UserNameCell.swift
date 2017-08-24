//
//  UserNameCell.swift
//  microjam
//
//  Created by Henrik Brustad on 24/08/2017.
//  Copyright © 2017 Charles Martin. All rights reserved.
//

import UIKit

class UserNameCell: UICollectionViewCell {
    
    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Please choose your username..."
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let textField: UITextField = {
        let field = UITextField()
        field.returnKeyType = .done
        field.placeholder = "Username"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endTextFieldEditing))
        contentView.addGestureRecognizer(tapGesture)
        
        UIPageViewController
        textField.delegate = self
        
        initSubviews()
    }
    
    private func initSubviews() {
        contentView.addSubview(label)
        contentView.addSubview(textField)
        
        textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        textField.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        textField.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 32).isActive = true
        label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -32).isActive = true
        label.bottomAnchor.constraint(equalTo: textField.topAnchor, constant: -16).isActive = true
        label.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
    
    // If user touches the screen when text field is editing, make it stop and hide the keyboard
    func endTextFieldEditing() {
        if textField.isEditing {
            textField.endEditing(true)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UserNameCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        print("Should do something here...")
        
        return true
    }
}






















