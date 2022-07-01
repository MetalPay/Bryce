//
//  Request.swift
//  Bryce
//
//  Created by Ephraim Russo on 1/22/19.
//

import Foundation
import Alamofire

public protocol DecodableError: Decodable, Error {
    
    static func decodingError(statusCode: Int?) -> Self
}

public enum BryceNetworkingError: Error {
    
    case noResponseBody
    
    case unexpectedResponseBodyFormat
    
    case malformedResponseBody
    
    case unknown(error: Error)
    
    case bodyDecodingFailed(error: Error)
}

public typealias DecodableResult<D: Decodable> = (Swift.Result<D, BryceNetworkingError>) -> Void

public typealias DecodableErrorResult<D: Decodable, T: DecodableError> = (Swift.Result<D, T>) -> Void

public typealias VoidResult = (Swift.Result<Void, Error>) -> Void

public typealias VoidDecodableErrorResult<T: DecodableError> = (Swift.Result<Void, T>) -> Void

extension Bryce {
    
    @discardableResult
    public func request<D: Decodable>(_ path: RouteComponent..., method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, result: @escaping DecodableResult<D>) -> DataRequest {
        
        let endpoint = Endpoint(components: path)
        
        return request(on: endpoint, method: method, headers: headers, validate: validate, as: responseType, result: result)
    }
    
    @discardableResult
    public func request<D: Decodable>(on endpoint: URLConvertible, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, result: @escaping DecodableResult<D>) -> DataRequest {
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.responseDecodable(of: D.self, queue: self.configuration.responseQueue, decoder: self.configuration.responseDecoder) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            self.handleDecodedResponse(alamofireResponse: alamofireResponse, result: result)
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request<E: Encodable, D: Decodable>(_ path: RouteComponent..., method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, result: @escaping DecodableResult<D>) -> DataRequest {
        
        let endpoint = Endpoint(components: path)
        
        return request(on: endpoint, method: method, parameters: parameters, encoding: encoding, customEncoder: customEncoder, headers: headers, validate: validate, as: responseType, result: result)
    }
    
    @discardableResult
    public func request<E: Encodable, D: Decodable>(on endpoint: URLConvertible, method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, result: @escaping DecodableResult<D>) -> DataRequest {
        
        let params = try! parameters.parameters(using: customEncoder ?? self.configuration.requestEncoder)
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, parameters: params, encoding: encoding, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.responseDecodable(of: D.self, queue: self.configuration.responseQueue, decoder: self.configuration.responseDecoder) { alamofireResponse in
                
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            self.handleDecodedResponse(alamofireResponse: alamofireResponse, result: result)
        }
        
        return dataRequest
    }
}

extension Bryce {
    
    @discardableResult
    public func request<D: Decodable, T: DecodableError>(_ path: RouteComponent..., method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, decodableErrorType: T.Type, result: @escaping DecodableErrorResult<D, T>) -> DataRequest {
        
        let endpoint = Endpoint(components: path)
        
        return request(on: endpoint, method: method, headers: headers, validate: validate, as: responseType, decodableErrorType: decodableErrorType, result: result)
    }
    
    @discardableResult
    public func request<D: Decodable, T: DecodableError>(on endpoint: URLConvertible, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, decodableErrorType: T.Type, result: @escaping DecodableErrorResult<D, T>) -> DataRequest {
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.responseDecodable(of: D.self, queue: self.configuration.responseQueue, decoder: self.configuration.responseDecoder) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            self.handleDecodedResponse(alamofireResponse: alamofireResponse, decodableErrorType: decodableErrorType, result: result)
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request<E: Encodable, D: Decodable, T: DecodableError>(_ path: RouteComponent..., method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, decodableErrorType: T.Type, result: @escaping DecodableErrorResult<D, T>) -> DataRequest {
     
        let endpoint = Endpoint(components: path)

        return request(on: endpoint, method: method, parameters: parameters, encoding: encoding, customEncoder: customEncoder, headers: headers, validate: validate, as: responseType, decodableErrorType: decodableErrorType, result: result)
    }
    
    @discardableResult
    public func request<E: Encodable, D: Decodable, T: DecodableError>(on endpoint: URLConvertible, method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ as responseType: D.Type, decodableErrorType: T.Type, result: @escaping DecodableErrorResult<D, T>) -> DataRequest {
        
        let params = try! parameters.parameters(using: customEncoder ?? self.configuration.requestEncoder)

        let dataRequest = prepareDataRequest(on: endpoint, method: method, parameters: params, encoding: encoding, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.responseDecodable(of: D.self, queue: self.configuration.responseQueue, decoder: self.configuration.responseDecoder) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            self.handleDecodedResponse(alamofireResponse: alamofireResponse, decodableErrorType: decodableErrorType, result: result)
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request<E: Encodable>(_ path: RouteComponent..., method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ result: @escaping VoidResult) -> DataRequest {
     
        let endpoint = Endpoint(components: path)
        
        return request(on: endpoint, method: method, parameters: parameters, encoding: encoding, customEncoder: customEncoder, headers: headers, validate: validate, result: result)
    }
    
    @discardableResult
    public func request<E: Encodable>(on endpoint: URLConvertible, method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ result: @escaping VoidResult) -> DataRequest {
        
        let params = try! parameters.parameters(using: customEncoder ?? self.configuration.requestEncoder)
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, parameters: params, encoding: encoding, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.response(queue: self.configuration.responseQueue) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)

            guard alamofireResponse.error == nil else { return result(.failure(alamofireResponse.error!)) }

            result(.success(()))
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request(_ path: RouteComponent..., method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ result: @escaping VoidResult) -> DataRequest {
        
        let endpoint = Endpoint(components: path)

        return request(on: endpoint, method: method, headers: headers, validate: validate, result: result)
    }
    
    @discardableResult
    public func request(on endpoint: URLConvertible, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, /*etagEnabled: Bool = false,*/ result: @escaping VoidResult) -> DataRequest {
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.response(queue: self.configuration.responseQueue) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            guard alamofireResponse.error == nil else { return result(.failure(alamofireResponse.error!)) }
            
            result(.success(()))
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request<E: Encodable, T: DecodableError>(_ path: RouteComponent..., method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, decodableErrorType: T.Type, /*etagEnabled: Bool = false,*/ result: @escaping VoidDecodableErrorResult<T>) -> DataRequest {
     
        let endpoint = Endpoint(components: path)
        
        return request(on: endpoint, method: method, parameters: parameters, encoding: encoding, customEncoder: customEncoder, headers: headers, validate: validate, decodableErrorType: decodableErrorType, result: result)
    }
    
    @discardableResult
    public func request<E: Encodable, T: DecodableError>(on endpoint: URLConvertible, method: HTTPMethod = .get, parameters: E, encoding: ParameterEncoding = URLEncoding.default, customEncoder: JSONEncoder? = nil, headers: HTTPHeaders? = nil, validate: Bool = true, decodableErrorType: T.Type, /*etagEnabled: Bool = false,*/ result: @escaping VoidDecodableErrorResult<T>) -> DataRequest {
        
        let params = try! parameters.parameters(using: customEncoder ?? self.configuration.requestEncoder)
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, parameters: params, encoding: encoding, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.response(queue: self.configuration.responseQueue) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)

            self.handleDefaultResponse(alamofireResponse: alamofireResponse, decodableErrorType: decodableErrorType, result: result)
        }
        
        return dataRequest
    }
    
    @discardableResult
    public func request<T: DecodableError>(_ path: RouteComponent..., method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, decodableErrorType: T.Type, /*etagEnabled: Bool = false,*/ result: @escaping VoidDecodableErrorResult<T>) -> DataRequest {
        
        let endpoint = Endpoint(components: path)

        return request(on: endpoint, method: method, headers: headers, validate: validate, decodableErrorType: decodableErrorType, result: result)
    }
    
    @discardableResult
    public func request<T: DecodableError>(on endpoint: URLConvertible, method: HTTPMethod = .get, headers: HTTPHeaders? = nil, validate: Bool = true, decodableErrorType: T.Type, /*etagEnabled: Bool = false,*/ result: @escaping VoidDecodableErrorResult<T>) -> DataRequest {
        
        let dataRequest = prepareDataRequest(on: endpoint, method: method, headers: headers, validate: validate, etagEnabled: false)
        
        dataRequest.response(queue: self.configuration.responseQueue) { alamofireResponse in
            
            EtagManager.storeEtag(endpoint: endpoint, method: method, etagEnabled: false, response: alamofireResponse)
            
            self.handleDefaultResponse(alamofireResponse: alamofireResponse, decodableErrorType: decodableErrorType, result: result)
        }
        
        return dataRequest
    }
}

extension Bryce {
    
    private func prepareDataRequest(on endpoint: URLConvertible, method: HTTPMethod, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.queryString, headers: HTTPHeaders?, validate: Bool, etagEnabled: Bool) -> DataRequest {
        
        let headersToSend = EtagManager.headersFrom(endpoint: endpoint, method: method, etagEnabled: etagEnabled, headers: headers)
        
        var dataRequest: DataRequest
        
        if etagEnabled && method == .get { dataRequest = self.configuration.session.requestWithoutCache(endpoint, method: method, parameters: parameters, encoding: encoding, headers: headersToSend) }
            
        else { dataRequest = self.configuration.session.request(endpoint, method: method, parameters: parameters, encoding: encoding, headers: headersToSend) }
        
        if validate { dataRequest = dataRequest.validate(statusCode: configuration.acceptableStatusCodes) }
        
        return dataRequest
    }
    
    private func handleDefaultResponse<T: DecodableError>(alamofireResponse: AFDataResponse<Data?>, decodableErrorType: T.Type, result: @escaping VoidDecodableErrorResult<T>) {
        
        if alamofireResponse.error == nil {
            
            return result(.success(()))
        }
        
        else {

            guard let data = alamofireResponse.data else {
                return result(.failure(T.decodingError(statusCode: alamofireResponse.response?.statusCode)))
            }
            
            do {
             
                let decodedError = try self.configuration.responseDecoder.decode(decodableErrorType, from: data)
                return result(.failure(decodedError))
            }
            
            catch {
                
                logResponseError(alamofireResponse: alamofireResponse, customDecodingError: error)
                return result(.failure(T.decodingError(statusCode: alamofireResponse.response?.statusCode)))
            }
        }
    }
    
    private func handleDecodedResponse<D: Decodable, T: DecodableError>(alamofireResponse: AFDataResponse<D>, decodableErrorType: T.Type, result: @escaping DecodableErrorResult<D, T>) {
        
        if alamofireResponse.error == nil {
            
            if let serialized = alamofireResponse.result.value { return result(.success(serialized)) }
                
            else { return result(.failure(T.decodingError(statusCode: alamofireResponse.response?.statusCode))) }
        }
            
        else {

            guard let data = alamofireResponse.data else {
                return result(.failure(T.decodingError(statusCode: alamofireResponse.response?.statusCode)))
            }
            
            do {
             
                let decodedError = try self.configuration.responseDecoder.decode(decodableErrorType, from: data)
                return result(.failure(decodedError))
            }
            
            catch {
                
                logResponseError(alamofireResponse: alamofireResponse, customDecodingError: error)
                return result(.failure(T.decodingError(statusCode: alamofireResponse.response?.statusCode)))
            }
        }
    }
        
    private func handleDecodedResponse<D: Decodable>(alamofireResponse: AFDataResponse<D>, result: @escaping DecodableResult<D>) {
        
        if alamofireResponse.error == nil {
            
            if let serialized = alamofireResponse.result.value { return result(.success(serialized)) }
                
            else { return result(.failure(.noResponseBody)) }
        }
            
        else {
            logResponseError(alamofireResponse: alamofireResponse, customDecodingError: nil)
            return result(.failure(.bodyDecodingFailed(error: alamofireResponse.error!)))
        }
    }
}

extension Bryce {
    
    private func logResponseError(alamofireResponse: AFDataResponse<Data>, customDecodingError: Error?) {
        
        guard let alamofireResponseError = alamofireResponse.error else { return }
        
        let method = alamofireResponse.request?.httpMethod ?? ""
        let urlString = alamofireResponse.request?.url?.absoluteString ?? ""
        
        print("***************************************")
        print(" ")
        
        self.log(.error, "Response serialization for request failed: \(method) on \(urlString)")
        print(" ")
        self.log(.error, "Alamofire response error: \(alamofireResponseError)")
        print(" ")

        if let error = customDecodingError {
                        
            self.log(.error, "Custom decodable error serialization: \(error)")
            print(" ")
        }

        print("***************************************")
    }
    
    private func logResponseError<D: Decodable>(alamofireResponse: AFDataResponse<D>, customDecodingError: Error?) {

        guard let alamofireResponseError = alamofireResponse.error else { return }
        
        let method = alamofireResponse.request?.httpMethod ?? ""
        let urlString = alamofireResponse.request?.url?.absoluteString ?? ""
        
        print("***************************************")
        print(" ")
        self.log(.error, "Response serialization for request failed: \(method) on \(urlString)")
        print(" ")
        self.log(.error, "Alamofire response error: \(alamofireResponseError)")
        print(" ")

        if let error = customDecodingError {
                        
            self.log(.error, "Custom decodable error serialization: \(error)")
            print(" ")
        }

        print("***************************************")
    }
}

extension Alamofire.Session{
    @discardableResult
    open func requestWithoutCache(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)// also you can add URLRequest.CachePolicy here as parameter
        -> DataRequest
    {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.cachePolicy = .reloadIgnoringCacheData // <<== Cache disabled
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        } catch {
            return request("")
        }
    }
}
