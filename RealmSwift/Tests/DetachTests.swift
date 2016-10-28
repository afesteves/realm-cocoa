////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import RealmSwift

class DetachTests: TestCase {
    typealias ObjBool = SwiftBoolObject
    typealias Obj = SwiftObject
    typealias ObjList = SwiftListOfSwiftObject
    typealias ObjLists = SwiftDoubleListOfSwiftObject
    
    override func setUp() {
        super.setUp()
        
    }
    override func tearDown() {
        super.tearDown()
    }
    
    func testDetach() {
        let root = ObjLists()
        let listA = ObjList()
        let listB = ObjList()
        let objA1 = Obj()
        let objA2 = Obj()
        let objB1 = Obj()
        let objB2 = Obj()
        let boolA1 = ObjBool()
        let boolA2 = ObjBool()
        
        root.array.append(objectsIn: [listA, listB])
        listA.array.append(objectsIn: [objA1, objA2])
        listB.array.append(objectsIn: [objB1, objB2])
        objA1.stringCol = "A1"
        objA2.stringCol = "A2"
        objB1.stringCol = "B1"
        objB2.stringCol = "B2"
        objA1.objectCol = boolA1
        objA2.objectCol = boolA2
        boolA1.boolCol = true
        boolA2.boolCol = true
        
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(root)
        }
        
        let shallow = root.detach(0)
        let depth1 = root.detach(1)
        let depth2 = root.detach(2)
        let depth3 = root.detach(3)
        let depth4 = root.detach(4)
        let deep = root.detach(nil)
        
        let getDepth1 = {(root: ObjLists) in root.array}
        let getDepth2 = {getDepth1($0)[0]}
        let getDepth3 = {getDepth2($0).array}
        let getDepth4 = {getDepth3($0)[0]}
        let getDepth5 = {getDepth4($0).stringCol}
        let getDepth6 = {getDepth4($0).objectCol?.boolCol}
        
        let newBool = false
        let newString = "123"
        
        try! realm.write {
            getDepth4(root).stringCol = newString
            getDepth4(root).objectCol?.boolCol = false
        }
                
        XCTAssertEqual(getDepth5(root), newString)
        XCTAssertEqual(getDepth5(shallow), newString)
        XCTAssertEqual(getDepth5(depth1), newString)
        XCTAssertEqual(getDepth5(depth2), newString)
        XCTAssertEqual(getDepth5(depth3), newString)
        XCTAssertEqual(getDepth5(depth4), "A1")
        XCTAssertEqual(getDepth5(deep), "A1")
        
        XCTAssertEqual(getDepth6(root), newBool)
        XCTAssertEqual(getDepth6(shallow), newBool)
        XCTAssertEqual(getDepth6(depth1), newBool)
        XCTAssertEqual(getDepth6(depth2), newBool)
        XCTAssertEqual(getDepth6(depth3), newBool)
        XCTAssertEqual(getDepth6(depth4), newBool)
        XCTAssertEqual(getDepth6(deep), true)
    }
}
