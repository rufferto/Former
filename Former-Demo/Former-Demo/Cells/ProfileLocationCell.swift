//
//  ProfileLocationCell.swift
//  Former-Demo
//
//  Created by Barry Wilson on 8/19/16.
//  Copyright © 2016 Ryo Aoyama. All rights reserved.
//

import UIKit
import Former
import CoreLocation
import MapKit

final class ProfileLocationCell: UITableViewCell, LabelFormableRow {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTextLabel: UILabel!
	
	var locationManager = CLLocationManager()
	var location: CLLocation?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		titleLabel.textColor = .formerColor()
		subTextLabel.textColor = .formerSubColor()
	}
	
	func formTextLabel() -> UILabel? {
		return titleLabel
	}
	
	func formSubTextLabel() -> UILabel? {
		return subTextLabel
	}
	
	func updateWithRowFormer(rowFormer: RowFormer) {
		locationManager.requestWhenInUseAuthorization()
	}
	
}

class MapViewController : UIViewController, MKMapViewDelegate {
	
	var row: LabelRowFormer<ProfileLocationCell>!
	var completionCallback : ((UIViewController) -> ())?
	
	lazy var mapView : MKMapView = { [unowned self] in
		let v = MKMapView(frame: self.view.bounds)
		v.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
		return v
		}()
	
	lazy var pinView: UIImageView = { [unowned self] in
		let v = UIImageView(frame: CGRectMake(0, 0, 50, 50))
		v.image = UIImage(named:"locationPin")
		v.image = v.image?.imageWithRenderingMode(.AlwaysTemplate)
		v.tintColor = UIView().tintColor
		v.backgroundColor = .clearColor()
		v.clipsToBounds = true
		v.contentMode = .ScaleAspectFit
		v.userInteractionEnabled = false
		return v
		}()
	
	let width: CGFloat = 10.0
	let height: CGFloat = 5.0
	
	lazy var ellipse: UIBezierPath = { [unowned self] in
		let ellipse = UIBezierPath(ovalInRect: CGRectMake(0 , 0, self.width, self.height))
		return ellipse
		}()
	
	lazy var ellipsisLayer: CAShapeLayer = { [unowned self] in
		let layer = CAShapeLayer()
		layer.bounds = CGRectMake(0, 0, self.width, self.height)
		layer.path = self.ellipse.CGPath
		layer.fillColor = UIColor.grayColor().CGColor
		layer.fillRule = kCAFillRuleNonZero
		layer.lineCap = kCALineCapButt
		layer.lineDashPattern = nil
		layer.lineDashPhase = 0.0
		layer.lineJoin = kCALineJoinMiter
		layer.lineWidth = 1.0
		layer.miterLimit = 10.0
		layer.strokeColor = UIColor.grayColor().CGColor
		return layer
		}()
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nil, bundle: nil)
	}
	
	convenience init(_ callback: (UIViewController) -> ()){
		self.init(nibName: nil, bundle: nil)
		completionCallback = callback
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(mapView)
		
		mapView.showsUserLocation = true
		mapView.mapType = .Hybrid
		mapView.delegate = self
		mapView.addSubview(pinView)
		mapView.layer.insertSublayer(ellipsisLayer, below: pinView.layer)
		
		let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(MapViewController.tappedDone(_:)))
		button.title = "Done"
		navigationItem.rightBarButtonItem = button
		
		if let location = row.cell.location {
			let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 400, 400)
			mapView.setRegion(region, animated: true)
		}
		else if let location = row.cell.locationManager.location {
			let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 400, 400)
			mapView.setRegion(region, animated: true)
		}
		updateTitle()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		let center = mapView.convertCoordinate(mapView.centerCoordinate, toPointToView: pinView)
		pinView.center = CGPointMake(center.x, center.y - (CGRectGetHeight(pinView.bounds)/2))
		ellipsisLayer.position = center
	}
	
	
	func tappedDone(sender: UIBarButtonItem){
		let target = mapView.convertPoint(ellipsisLayer.position, toCoordinateFromView: mapView)
		let location = CLLocation(latitude: target.latitude, longitude: target.longitude)
		row.cell.location = location
		row.cell.subTextLabel.text = location.description
		completionCallback?(self)
	}
	
	func updateTitle(){
		let fmt = NSNumberFormatter()
		fmt.maximumFractionDigits = 4
		fmt.minimumFractionDigits = 4
		let latitude = fmt.stringFromNumber(mapView.centerCoordinate.latitude)!
		let longitude = fmt.stringFromNumber(mapView.centerCoordinate.longitude)!
		title = "\(latitude), \(longitude)"
	}
	
	func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
		ellipsisLayer.transform = CATransform3DMakeScale(0.5, 0.5, 1)
		UIView.animateWithDuration(0.2, animations: { [weak self] in
			self?.pinView.center = CGPointMake(self!.pinView.center.x, self!.pinView.center.y - 10)
			})
	}
	
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		ellipsisLayer.transform = CATransform3DIdentity
		UIView.animateWithDuration(0.2, animations: { [weak self] in
			self?.pinView.center = CGPointMake(self!.pinView.center.x, self!.pinView.center.y + 10)
			})
		updateTitle()
	}
	
}
