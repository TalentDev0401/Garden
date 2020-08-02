//
//  Spring.swift
//  Garden
//
//  Created by Admin on 05.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import SpriteKit

public extension SKAction {
	static func animate<Node>(
		_ keyPath: ReferenceWritableKeyPath<Node, CGFloat>,
		_ transformation: ValueTransformation,
		using settings: SpringAnimationSettings
	) -> SKAction where Node: SKNode {
		let function = Spring.timingFunction(with: settings.springProperties)
		let duration = CGFloat(settings.duration)
		let applier = transformation.valueApplier(on: keyPath)
		let easingFactor = easingFunction(portion: 1.0)
		
		return .customAction(withDuration: settings.duration) { node, elapsedTime in
			let time = elapsedTime / duration
			let springValue = function(time)
			let eased = springValue + easingFactor(time) * (1 - springValue)
			applier(node as! Node, eased)
		}
	}
	
	/// - Parameter portion: the fraction of the time to ease for (from the end, so e.g. 0.2 means we ease from 0.8 to 1.0)
	private static func easingFunction(portion: CGFloat) -> ((CGFloat) -> CGFloat) {
		let easingScaling = 0.5 * .pi
		return { time in
			guard time > 1 - portion else { return 0 }
			let offsetTime = (time + portion - 1) / portion
			return 1 - cos(easingScaling * portion * offsetTime)
		}
	}
	
	struct SpringAnimationSettings {
		var duration: TimeInterval
		var springProperties: Spring.Properties
		
		public init(duration: TimeInterval, springProperties: Spring.Properties) {
			self.duration = duration
			self.springProperties = springProperties
		}
		
		public init(duration: TimeInterval, dampingRatio: CGFloat, initialVelocity: CGFloat) {
			self.duration = duration
			self.springProperties = .init(
				dampingRatio: dampingRatio,
				initialVelocity: initialVelocity
			)
		}
	}

	enum ValueTransformation {
		case change(to: CGFloat)
		case add(CGFloat)
		case multiply(by: CGFloat)
		
		func valueApplier<Node>(
			on keyPath: ReferenceWritableKeyPath<Node, CGFloat>
		) -> ((Node, CGFloat) -> Void) {
			switch self {
			case .change(to: let finalValue): // ends up at finalValue regardless of interference from other sources
				var _initialValue: CGFloat?
				return { node, springValue in
					let initialValue = _initialValue ?? node[keyPath: keyPath]
					_initialValue = initialValue
					node[keyPath: keyPath] = initialValue + springValue * (finalValue - initialValue)
				}
				
			case .add(let offset): // overall always applies the given offset, also working in parallel with other .add transformations
				var lastSpringValue = 0.0
				return { node, springValue in
					node[keyPath: keyPath] += (springValue - lastSpringValue) * offset
					lastSpringValue = springValue
				}
				
			case .multiply(by: let factor): // overall always applies the given offset, also working in parallel with other .multiply transformations
				var lastMultiplier = 1.0
				return { node, springValue in
					let multiplier = (factor - 1) * springValue + 1
					node[keyPath: keyPath] *= multiplier / lastMultiplier
					lastMultiplier = multiplier
				}
			}
		}
	}
}

private typealias FloatLiteralType = CGFloat

public enum Spring {
	public static func timingFunction(with properties: Properties) -> (CGFloat) -> CGFloat {
		// lots of math adapted from http://www.ryanjuckett.com/programming/damped-springs/
		
		let damping = Damping(ratio: properties.dampingRatio)
		let naturalFrequency = damping.naturalFrequency
		let initialVelocity = -properties.initialVelocity // flipped because these formulas assume resting position at 0
		
		switch damping {
		case .underdamped(let ratio):
			let dampedFrequency = naturalFrequency * sqrt(1 - ratio * ratio)
			let coefficient = (ratio * naturalFrequency + initialVelocity) / dampedFrequency
			
			return { time in
				guard time < 1 else { return 1 }
				let dampingExp = exp(-naturalFrequency * ratio * time)
				let scaledFrequency = dampedFrequency * time
				let dampened1 = cos(scaledFrequency)
				let dampened2 = coefficient * sin(scaledFrequency)
				return 1 - (dampened1 + dampened2) * dampingExp
			}
			
		case .criticallyDamped:
			let coefficient = initialVelocity + naturalFrequency
			
			return { time in
			guard time < 1 else { return 1 }
				let dampingExp = exp(-naturalFrequency * time)
				return 1 - (coefficient * time + 1) * dampingExp
			}
			
		case .overdamped(let ratio):
			let root = sqrt(ratio * ratio - 1)
			let z1 = naturalFrequency * (-ratio - root)
			let z2 = naturalFrequency * (-ratio + root)
			let coefficient1 = (initialVelocity - z2) / (z1 - z2)
			let coefficient2 = 1 - coefficient1
			
			return { time in
			guard time < 1 else { return 1 }
				let dampened1 = coefficient1 * exp(z1 * time)
				let dampened2 = coefficient2 * exp(z2 * time)
				return 1 - (dampened1 + dampened2)
			}
		}
	}
	
	private enum Damping {
		case underdamped(_ ratio: CGFloat)
		case criticallyDamped
		case overdamped(_ ratio: CGFloat)
		
		var naturalFrequency: CGFloat {
			// picked manually to visually approximate the behavior of UIKit (with duration 1, if that matters)
			let base = 9.2
			switch self {
			case .underdamped(let ratio):
				return base * (1 + 3.71 * pow(1 - ratio, 3.46))
			case .criticallyDamped:
				return base
			case .overdamped(let ratio):
				return base * pow(ratio, 0.6)
			}
		}
		
		init(ratio: CGFloat) {
			precondition(ratio > 0, "invalid damping ratio!")
			
			if ratio < 1 {
				self = .underdamped(ratio)
			} else if ratio == 1 {
				self = .criticallyDamped
			} else {
				self = .overdamped(ratio)
			}
		}
	}
	
	public struct Properties {
		/**
		The ratio of the spring's damping coefficient to its critical damping coefficient.
		
		Possible values:
		- `0`: **undamped**; the spring will never slow down (this is **invalid** and will yield an error)
		- `0..<1`: **underdamped**; the spring will overshoot its resting position at least once
		- `1`: **critically damped**; the spring will reach its resting position in minimal time
		- `1...`: **overdamped**; the spring won't overshoot but will take longer due to being slowed down
		*/
		let dampingRatio: CGFloat
		
		/**
		How fast the spring is initially moving, relative to the total distance to cover and the total duration.
		
		For example, an initial velocity of 2 means the spring would be moving fast enough to cover the entire distance twice over the course of the animation if it were moving at a constant speed.
		*/
		let initialVelocity: CGFloat
		
		/**
		Check out the individual properties' documentation for additional information.
		
		- Parameters:
		- dampingRatio: The ratio of the spring's damping coefficient to its critical damping coefficient.
		- initialVelocity: How fast the spring is initially moving, relative to the total distance to cover and the total duration.
		*/
		public init(dampingRatio: CGFloat, initialVelocity: CGFloat) {
			self.dampingRatio = dampingRatio
			
			self.initialVelocity = initialVelocity
		}
	}
}
