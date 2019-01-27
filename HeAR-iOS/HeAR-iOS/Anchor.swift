//
//  Anchor.swift
//  HeAR-iOS
//
//  Created by Francesco Valela on 2019-01-26.
//  Copyright © 2019 Francesco Valela. All rights reserved.
//

import UIKit
import ARKit

enum NodeType: String {
    case frontLabel = "frontLabel"
    case backLabel = "backLabel"
}

class Anchor: ARAnchor {
    var type: NodeType?
}
