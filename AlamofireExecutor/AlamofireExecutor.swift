
import Foundation
import Alamofire
import LSAPI

public class AlamofireExecutor: ExecutorType {
    public static let instance = AlamofireExecutor()
    
    private var validations: [Alamofire.DataRequest.Validation] = []
    private let interceptor: Alamofire.RequestInterceptor?
    public init(interceptor: Alamofire.RequestInterceptor? = nil) {
        self.interceptor = interceptor
    }

    public func execute(urlRequest: URLRequest, multipartFormData: LSAPI.MultipartFormData?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Cancelable {
        if let multipartFormData = multipartFormData {
            return doExecute(urlRequest: urlRequest, multipartFormData: multipartFormData, completionHandler: completionHandler)
        } else {
            return doExecute(urlRequest: urlRequest, completionHandler: completionHandler)
        }
    }
}

extension AlamofireExecutor {
    public func addValidation(_ validation: @escaping Alamofire.DataRequest.Validation) {
        self.validations.append(validation)
    }
}

extension DataRequest {
    fileprivate func addValidations(_ validations: [Alamofire.DataRequest.Validation]) -> Self {
        return validations.reduce(self) { (dataRequest, validation) in
            return dataRequest.validate(validation)
        }
    }
}

extension AlamofireExecutor {
    fileprivate func doExecute(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Cancelable {
//        let dataRequest = AF.request(urlRequest, interceptor: interceptor)
//            .addValidations(self.validations)
//            .validate(statusCode: 200..<300)
//            .response { completionHandler($0.data, $0.response, $0.error) }

        return AnonymousCancelable{}
    }

    fileprivate func doExecute(urlRequest: URLRequest, multipartFormData: @escaping LSAPI.MultipartFormData, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Cancelable {
        let dataRequest = AF.upload(multipartFormData: { (formData) in
            for bodyPart in multipartFormData() {
                formData.append(bodyPart.bodyStream, withLength: bodyPart.bodyContentLength, headers: Alamofire.HTTPHeaders(bodyPart.headers))
            }
        }, with: urlRequest, interceptor: interceptor)
        .addValidations(validations)
        .validate(statusCode: 200..<300)
            .response { (response) in
                switch response.result {
                case .failure(let error):
                    completionHandler(nil, nil, error)
                case .success(let data):
                    completionHandler(data, response.response, response.error)
                }
        }

        return AnonymousCancelable {
            print("dsd")
//            dataRequest?.tasks.forEach { $0.cancel() }
        }
    }
}

fileprivate class SerialCancelable: Cancelable {
    private var isCanceled: Bool = false
    
    var cancelable: Cancelable? {
        didSet {
            oldValue?.cancel()
            
            if self.isCanceled {
                self.cancelable?.cancel()
            }
        }
    }
    
    func cancel() {
        if self.isCanceled {
            return
        }
        
        self.isCanceled = true
        self.cancelable?.cancel()
    }
}

