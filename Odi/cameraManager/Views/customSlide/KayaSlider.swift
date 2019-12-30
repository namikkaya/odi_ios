//
//  KayaSlider.swift
//  Odi
//
//  Created by Nok Danışmanlık on 4.12.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class KayaSlider: UISlider {
  @IBInspectable var trackHeight: CGFloat = 2

  override func trackRect(forBounds bounds: CGRect) -> CGRect {
    return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: trackHeight))
  }
}
