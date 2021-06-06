//
//  CGFloat+Scaling.swift
//  Voxcaster
//
//  Created by Steven Troughton-Smith on 29/07/2020.
//

import UIKit

public let supportsMacIdiom = !(UIDevice.current.userInterfaceIdiom == .pad)

@inlinable func UIFloat(_ value: CGFloat) -> CGFloat
{
    return round((value == 0.5) ? 0.5 : value * (supportsMacIdiom ? 0.77 : 1.0))
}
