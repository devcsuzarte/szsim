//
//  MKPolyline+Coordinates.swift
//  SZSIM
//

import MapKit

extension MKPolyline {
    /// The polyline's coordinates as an array.
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: pointCount
        )
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}
