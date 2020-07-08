
import XCTest
import BryceNetworking

extension RouteComponent {
    
    static let posts: RouteComponent = "posts"
    
    static let comments: RouteComponent = "comments"
}

struct BryceTestError: DecodableError {
    
    static func decodingError() -> BryceTestError {
        
        return .init(error: "error_decoding_failure", message: "Something went wrong.")
    }
    
    let error: String
    let message: String
}

class HTTPTests: XCTestCase {
    
    var timeout: TimeInterval = 500
    
    let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Bryce.shared.logout()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}

// MARK: Authentication

extension HTTPTests {

    func testBasicAuthenticationHeaders() {
        
        let auth: Authorization = .basic(username: "jdoe123", password: "Password123", expiration: nil)
        XCTAssertEqual(auth.headerValue, "Basic amRvZTEyMzpQYXNzd29yZDEyMw==")
        
        let expectation = XCTestExpectation(description: "Basic authentication expectation.")
        
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL
            )
        )
        
        Bryce.shared.authorization = auth
        
        let endpoint = Endpoint(components: "posts", "1")
        
        let request = Bryce.shared.request(on: endpoint, as: Post.self) { result in
            
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            
            expectation.fulfill()
        }
        
        XCTAssertEqual(request.request?.allHTTPHeaderFields?["Authorization"], auth.headerValue)

        wait(for: [expectation], timeout: timeout)
    }
    
    func testBearerAuthenticationHeaders() {
        
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let auth: Authorization = .bearer(token: token, refreshToken: nil, expiration: nil)
        XCTAssertEqual(auth.headerValue, "Bearer \(token)")
        
        let expectation = XCTestExpectation(description: "Basic authentication expectation.")
        
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL
            )
        )
        
        Bryce.shared.authorization = auth
        
        let endpoint = Endpoint(components: "posts", "1")
        
        let request = Bryce.shared.request(on: endpoint, as: Post.self) { result in
            
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            
            expectation.fulfill()
        }
        
        XCTAssertEqual(request.request?.allHTTPHeaderFields?["Authorization"], auth.headerValue)
        
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: Keychain

extension HTTPTests {
    
    func testKeychainPersistence() {
                
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            authorizationKeychainService: "com.bryce.test"
            )
        )
        
        func persist() {
            
            let auth: Authorization = .basic(username: "jdoe123", password: "Password123", expiration: nil)
            Bryce.shared.authorization = auth
        }
        
        func read(expectsValue: Bool) {
            
            if expectsValue {
                XCTAssertNotNil(Bryce.shared.authorization)
                XCTAssertEqual(Bryce.shared.authorization?.headerValue, "Basic amRvZTEyMzpQYXNzd29yZDEyMw==")
            }
            else {
                XCTAssertNil(Bryce.shared.authorization)
            }
        }
        
        func clear() {
            Bryce.shared.logout()
        }
        
        for _ in 0..<10 {
            read(expectsValue: false)
            persist()
            read(expectsValue: true)
            clear()
            read(expectsValue: false)
            clear()
        }
    }
}

// MARK: Certificate Pinning

extension HTTPTests {
    
    func testRequestSignatures() {
                
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL
            )
        )
        
        struct Post: Decodable {
            
            let userId: Int
            let id: Int
            let title: String
            let body: String
        }
        
        let expectation0 = XCTestExpectation(description: "DefaultDataResponse expectation.")
        let expectation1 = XCTestExpectation(description: "ErrorResponse expectation.")
        let expectation2 = XCTestExpectation(description: "DataResponse expectation.")
        let expectation3 = XCTestExpectation(description: "JSONResponse expectation.")

        Bryce.shared.request(.posts, as: [Post].self) { result in
                        
            XCTAssertNotNil(try? result.get())
            expectation0.fulfill()
        }
        
        Bryce.shared.request(on: Endpoint(components: "posts")) { result in
            
            switch result {
            case .success: XCTAssert(true)
            case .failure: XCTAssert(false)
            }
            expectation1.fulfill()
        }
        
        Bryce.shared.request(on: Endpoint(components: .posts), as: Post.self) { result in
        
            XCTAssertNotNil(result.error)
            expectation2.fulfill()
        }
        
        struct Parameters: Encodable {
            
            let postId: Int
        }
        
        Bryce.shared.request(.comments, parameters: Parameters(postId: 1), as: [Comment].self) { result in
            
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!.count, 5)
            XCTAssertEqual(result.value!.first!.name, "id labore ex et quam laborum")
            
            expectation3.fulfill()
        }
        
        wait(for: [
            expectation0,
            expectation1,
            expectation2,
            expectation3,
            ], timeout: 100)
    }

    func testValidCertificatePinning() {

        let expectation = XCTestExpectation(description: "Valid cert pinning expectation.")

        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .certifcatePinning(bundle: .main))
        )
        
        Bryce.shared.request(.posts, .id("1"), as: Post.self) { result in
            
            XCTAssertNotNil(result.error)
            XCTAssertNil(result.value)
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
    
    // Un-check valid_cert.crt from Target Membership before running this test.
    /*
    func testInvalidCertificatePinning() {

        let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
        let expectation = XCTestExpectation(description: "Invalid Cert pinning expectation.")
    
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .certifcatePinning(bundle: .main))
        )
        
        let endpoint = Endpoint(components: "posts", "1")
        
        Bryce.shared.request(on: endpoint) { (post: Post?, error: Error?) in
            
            XCTAssertNotNil(error)
            XCTAssertNil(post)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    */

    func testNoSecurityPolicy() {

        let expectation = XCTestExpectation(description: "No sercurity policy expectation.")

        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .none,
            logLevel: .debug)
        )
        
        Bryce.shared.request(.posts, .id("1"), as: Post.self) { result in
            
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
//    func testEtagHTTPRequests() {
//
//        let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
//        let expectation = XCTestExpectation(description: "HTTP request expectation.")
//
//        Bryce.shared.use(Configuration.init(
//            baseUrl: baseURL,
//            securityPolicy: .none,
//            logLevel: .debug)
//        )
//
//        let endpoint = Endpoint(components: "posts", "1")
//
//        Bryce.shared.request(on: endpoint, etagEnabled: true, as: Post.self) { result in
//
//            XCTAssertNil(result.error)
//            XCTAssertNotNil(result.value)
//
//            Bryce.shared.request(on: endpoint, etagEnabled: true, as: Post.self) { result in
//
//                XCTAssertNil(result.error)
//                XCTAssertNotNil(result.value)
//
//                Bryce.shared.request(on: endpoint, as: Post.self) { result in
//
//                    XCTAssertNil(result.error)
//                    XCTAssertNotNil(result.value)
//
//                    expectation.fulfill()
//                }
//            }
//        }
//
//        wait(for: [expectation], timeout: timeout)
//    }
    
    func testSerializationError() {
        
        let expectation = XCTestExpectation(description: "Decodable error.")

        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            logLevel: .debug
            )
        )
        
        Bryce.shared.request(.posts, .id("1"), as: Comment.self) { result in
            
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            
            switch result.error! {
                
            case .bodyDecodingFailed: XCTAssertTrue(true)
            default: XCTAssertTrue(false)
            }
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout)
    }
    
    func testRequestRetrierQueue() {
        
        func makeRequest(responseCode: UInt) {
            
            let expectation = self.expectation(description: "\(responseCode) Expectation")
            Bryce.shared.request(RouteComponent("\(responseCode)")!) { result in
                
                if (200..<400).contains(responseCode) {
                    XCTAssertNil(result.error, "Expected successful response code to have no error")
                } else if (400..<600).contains(responseCode) {
                    XCTAssertNotNil(result.error, "Expected error response code to contain error")
                }
                expectation.fulfill()
            }
        }
        
        let baseURL = URL(string: "https://httpstat.us")!

        let handler: BryceAuthorizationRefreshHandler = { request, callback in

            callback()
        }
        
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .none,
            logLevel: .debug,
            authorizationRefreshHandler: handler
        ))
        
        Bryce.shared.authorization = .bearer(token: "API_TOKEN", refreshToken: "REFRESH_TOKEN", expiration: Date(timeIntervalSinceNow: 3600))
        
        makeRequest(responseCode: 401)
        makeRequest(responseCode: 200)
//        makeRequest(responseCode: 201)
//        makeRequest(responseCode: 204)
//        makeRequest(responseCode: 400)
        
        waitForExpectations(timeout: 20)
    }
    
    func test401ResponseHandler() {
        
        let expectation0 = XCTestExpectation(description: "401 handler expectation.")
        
        let expectation1 = XCTestExpectation(description: "401 handler expectation.")
        
        let baseURL = URL(string: "https://httpstat.us")!
        
        let handler: BryceAuthorizationRefreshHandler = { request, callback in
            
            print("Handle 401")
                        
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.35) {
                                
                let newToken = UUID().uuidString
                let newRefreshTokeb = UUID().uuidString
                let newAuth = Authorization(type: .bearer, token: newToken, refreshToken: newRefreshTokeb, expiration: Date(timeIntervalSinceNow: 3600))
                Bryce.shared.authorization = newAuth
                
                XCTAssertEqual(newAuth, Bryce.shared.authorization)
                
                expectation0.fulfill()
                
                callback()
            }
        }
        
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .none,
            logLevel: .debug,
            authorizationRefreshHandler: handler
        ))
        
        Bryce.shared.authorization = .bearer(token: UUID().uuidString, refreshToken: UUID().uuidString, expiration: Date(timeIntervalSinceNow: 3600))
        
        print("Sending original request")
        
        Bryce.shared.request("401") { result in
            
            XCTAssertNotNil(result.error)
            
            print("Finish original request")
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation0, expectation1], timeout: timeout)
    }
    
    func testLogout() {
        
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let auth: Authorization = .bearer(token: token, refreshToken: nil, expiration: nil)
        XCTAssertEqual(auth.headerValue, "Bearer \(token)")
                
        Bryce.shared.use(Configuration.init(
            baseUrl: baseURL,
            securityPolicy: .none,
            logLevel: .debug)
        )
        
        Bryce.shared.authorization = auth
        
        Bryce.shared.logout()
        
        XCTAssertNil(Bryce.shared.authorization)
    }
}
