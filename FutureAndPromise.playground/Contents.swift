import Foundation

//Generic enum to combine the result and error.
enum Result<Value> {
    case value(Value)
    case error(Error)
}

//Generic Future class to define the base for Future communication
class Future<Value> {
    fileprivate var result: Result<Value>? {
        didSet{
            result.map(report)
        }
    }
    private lazy var callbacks = [(result:Result<Value>)->Void]()
    
    func observe(with callback: @escaping (Result<Value>)->Void ){
        callbacks.append(callback)
        result.map(callback)
    }
    
    private func report(result: Result<Value>){
        for callback in callbacks{
            callback(result)
        }
    }
}

//Generic Promise class, extends Future and resolves the Value and Error of result( of Future).
class Promise<Value>: Future<Value> {
    init(_ value:Value? = nil) {
        super.init()
        result = value.map(Result.value)
    }
    
    func resolve(with value:Value){
        result = .value(value)
    }
    
    func reject(with error:Error){
        result = .error(error)
    }
}

///////////////////////////////////DEMO/////////////////////////////////////////////////////////////////////////////

extension URLSession {
    func request(url: URL) -> Future<Data>{
        let promise = Promise<Data>()
        let task = dataTask(with:url){data, _, error in
            if let error = error{
                promise.reject(with: error)
            }
            if let data = data{
                promise.resolve(with:data)
            }
        }
        task.resume()
        return promise
    }
}


let stringURL = "http://ip.jsontest.com/?callback=awesome"
let url = URL(string: stringURL)
if let url = url{
    URLSession.shared.request(url: url).observe { result in
        switch result {
        case .value(let value):
            let response = String(data: value, encoding: .utf8)
            print("Error: \(String(describing: response))")
        case .error(let error):
            print(error)
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
