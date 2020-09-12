import Foundation

func loadJSON<T: Decodable>( file: String, bundle: Bundle) -> T {
    let url = bundle.url(forResource: file, withExtension: "json")!
    let jsonData = try! Data(contentsOf: url)
    return try! JSONDecoder().decode(T.self, from: jsonData)
}

func loadJSON<T: Decodable>( file: String) -> T where T: AnyObject {
    let url = Bundle(for: T.self).url(forResource: file, withExtension: "json")!
    let jsonData = try! Data(contentsOf: url)
    return try! JSONDecoder().decode(T.self, from: jsonData)
}

func saveJSON<T: Encodable>( fileName: String, value: T){
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(value)
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
    try! data.write(to: url.appendingPathComponent("\(fileName).json"))
}
