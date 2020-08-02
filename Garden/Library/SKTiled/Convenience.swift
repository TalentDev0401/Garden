//
//  Convenience.swift
//  Garden
//
//  Created by Admin on 05.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import SpriteKit

// MARK: - Move

public extension SKAction {
	static func move(by delta: CGVector, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			animate(\SKNode.position.x, .add(delta.dx), using: settings),
			animate(\SKNode.position.y, .add(delta.dy), using: settings),
		])
	}
	
	static func move(to location: CGPoint, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			animate(\SKNode.position.x, .change(to: location.x), using: settings),
			animate(\SKNode.position.y, .change(to: location.y), using: settings),
		])
	}
	
	static func moveBy(x deltaX: CGFloat, y deltaY: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			animate(\SKNode.position.x, .add(deltaX), using: settings),
			animate(\SKNode.position.y, .add(deltaY), using: settings),
		])
	}
	
	static func moveTo(x: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.position.x, .change(to: x), using: settings)
	}
	
	static func moveTo(y: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.position.y, .change(to: y), using: settings)
	}
}

// MARK: - Rotate

public extension SKAction {
	static func rotate(byAngle radians: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.zRotation, .add(radians), using: settings)
	}
	
	static func rotate(toAngle radians: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.zRotation, .change(to: radians), using: settings)
	}
}

// MARK: - Speed

public extension SKAction {
	static func speed(by speed: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.speed, .multiply(by: speed), using: settings)
	}
	
	static func speed(to speed: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.speed, .change(to: speed), using: settings)
	}
}

// MARK: - Scale

public extension SKAction {
	static func scale(by scale: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		scaleBy(x: scale, y: scale, using: settings)
	}
	
	static func scale(to scale: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		scaleTo(x: scale, y: scale, using: settings)
	}
	
	static func scaleBy(x: CGFloat, y: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			animate(\SKNode.xScale, .multiply(by: x), using: settings),
			animate(\SKNode.yScale, .multiply(by: y), using: settings),
		])
	}
	
	static func scaleTo(x scale: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.xScale, .change(to: scale), using: settings)
	}
	
	static func scaleTo(y scale: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.yScale, .change(to: scale), using: settings)
	}
	
	static func scaleTo(x: CGFloat, y: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			scaleTo(x: x, using: settings),
			scaleTo(y: y, using: settings),
		])
	}
}

// MARK: - Fade

public extension SKAction {
	static func fadeIn(using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.alpha, .change(to: 1), using: settings)
	}
	
	static func fadeOut(using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.alpha, .change(to: 0), using: settings)
	}
	
	static func fadeAlpha(by factor: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.alpha, .multiply(by: factor), using: settings)
	}
	
	static func fadeAlpha(to factor: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKNode.alpha, .change(to: factor), using: settings)
	}
}

// MARK: - Resize

public extension SKAction {
	static func resizeTo(width: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKSpriteNode.size.width, .change(to: width), using: settings)
	}
	
	static func resizeTo(height: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKSpriteNode.size.height, .change(to: height), using: settings)
	}
	
	static func resizeBy(width: CGFloat, height: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			animate(\SKSpriteNode.size.width, .add(width), using: settings),
			animate(\SKSpriteNode.size.height, .add(height), using: settings),
		])
	}
	
	static func resizeTo(width: CGFloat, height: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		.group([
			resizeTo(width: width, using: settings),
			resizeTo(height: height, using: settings),
		])
	}
}

// MARK: - Colorize

public extension SKAction {
	static func colorize(withColorBlendFactor colorBlendFactor: CGFloat, using settings: SpringAnimationSettings) -> SKAction {
		animate(\SKSpriteNode.colorBlendFactor, .change(to: colorBlendFactor), using: settings)
	}
}
