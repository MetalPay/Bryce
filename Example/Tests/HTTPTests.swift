
import XCTest
import BryceNetworking

extension RouteComponent {
    
    static let posts: RouteComponent = "posts"
    
    static let comments: RouteComponent = "comments"
}

struct BryceTestError: DecodableError {
    
    static func decodingError(statusCode: Int? = nil) -> BryceTestError {
        
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
        Bryce.shared.teardown()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
    
//    func test401ResponseHandler() {
//
//        let expectation0 = XCTestExpectation(description: "401 handler expectation.")
//
//        let expectation1 = XCTestExpectation(description: "401 handler expectation.")
//
//        let baseURL = URL(string: "https://httpstat.us/401")!
//
//        let handler: BryceAuthorizationRefreshHandler = { request, callback in
//
//            print("Handle 401")
//
//            XCTAssertEqual(request.url, baseURL)
//
//            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.35) {
//
//                let newToken = UUID().uuidString
//                let newRefreshTokeb = UUID().uuidString
//                let newAuth = Authorization(type: .bearer, token: newToken, refreshToken: newRefreshTokeb, expiration: Date(timeIntervalSinceNow: 3600))
//                Bryce.shared.authorization = newAuth
//
//                XCTAssertEqual(newAuth, Bryce.shared.authorization)
//
//                expectation0.fulfill()
//
//                callback()
//            }
//        }
//
//        Bryce.shared.use(Configuration.init(
//            baseUrl: baseURL,
//            securityPolicy: .none,
//            logLevel: .debug,
//            authorizationRefreshHandler: handler
//        ))
//
//        Bryce.shared.authorization = .bearer(token: UUID().uuidString, refreshToken: UUID().uuidString, expiration: Date(timeIntervalSinceNow: 3600))
//
//        print("Sending original request")
//
//        Bryce.shared.request(on: baseURL) { result in
//
//            XCTAssertNotNil(result.error)
//
//            print("Finish original request")
//
//            expectation1.fulfill()
//        }
//
//        wait(for: [expectation0, expectation1], timeout: timeout)
//    }
    
//    func testLogout() {
//
//        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
//        let auth: Authorization = .bearer(token: token, refreshToken: nil, expiration: nil)
//        XCTAssertEqual(auth.headerValue, "Bearer \(token)")
//
//        Bryce.shared.use(Configuration.init(
//            baseUrl: baseURL,
//            securityPolicy: .none,
//            logLevel: .debug)
//        )
//
//        Bryce.shared.teardown()
//    }
}
