// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Inheritance {
    address owner;
    uint256 public lastAlive; //บันทึกเวลาที่เจ้าของยืนยันว่ายังมีชีวิต (เป็น timestamp)
    uint256 public totalPercentage; // เพื่อติดตามเปอร์เซ็นต์ที่จัดสรรทั้งหมด

    struct Inheritor { //กำหนดโครงสร้างข้อมูลสำหรับผู้รับมรดก 
        address payable inheritorAddress; //ที่อยู่หรือเป๋าตัง
        string name; // ชื่อผู้รับมรดก
        uint256 percentage; // เปอร์เซ็นต์การรับมรดก
    }

    Inheritor[4] public inheritors; // จำกัดผู้รับมรดกไม่เกิน 4 คน อาร์เรย์คือ inheritors

    modifier onlyOwner() { //ตรวจสอบเฉพาะเจ้าของสัญญา
        require(msg.sender == owner, unicode"มีเพียงเจ้าของเท่านั้นที่สามารถเรียกฟังก์ชันนี้ได้");
        _;
    }

    constructor() { //เจ้าของเป็นผู้ที่ deploy contract
        owner = msg.sender;
        lastAlive = block.timestamp;
        totalPercentage = 0;
    }

    // 1. เติมเงินลงในกองทุน
    function addFunds() external payable {}

    // 2. ดูยอดเงินในกองทุน
    function viewPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 3. เพิ่มผู้รับมรดก (โดยกำหนดเปอร์เซ็นต์)
    function addInheritor(address payable inheritorAddress, string calldata name, uint256 percentage) external onlyOwner {
        require(percentage > 0, unicode"เปอร์เซ็นต์ต้องมากกว่า 0");
        require(totalPercentage + percentage <= 100, unicode"เปอร์เซ็นต์รวมทั้งหมดต้องไม่เกิน 100%");
        
        for (uint256 i = 0; i < inheritors.length; i++) {
            if (inheritors[i].inheritorAddress == address(0)) { //ตรวจสอบอาร์เรย์มีตำแหน่งว่าง inheritorAddress ยังเป็น address(0) หรือไม่
                inheritors[i] = Inheritor(inheritorAddress, name, percentage);
                totalPercentage += percentage;
                return;
            }
        }
        revert(unicode"ไม่สามารถเพิ่มผู้รับมรดกเกิน 4 คน"); //ถ้าเกินจะแสดงข้อความ
    }

    // 4. ลบผู้รับมรดก
    function removeInheritor(address inheritorAddress) external onlyOwner {
        for (uint256 i = 0; i < inheritors.length; i++) {
            if (inheritors[i].inheritorAddress == inheritorAddress) {
                totalPercentage -= inheritors[i].percentage; //ถ้าพบที่อยู่ในอาร์เรย์ก็ลบโดยเปลี่ยนเป็น address(0) และลดค่า totalPercentage ตามเปอร์เซ็นต์ของผู้รับมรดกคนนั้น
                inheritors[i] = Inheritor(payable(0), "", 0); // รีเซ็ตตำแหน่งในอาร์เรย์
                return;
            }
        }

        revert(unicode"ไม่พบผู้รับมรดก");
    }

    // 5. ดูรายชื่อผู้รับมรดก
    function viewInheritors() external view returns (Inheritor[4] memory) {
        return inheritors;
    }

    // 6. แจกจ่ายมรดกตามเปอร์เซ็นต์ที่กำหนด
    function distributeInheritance() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, unicode"ไม่มีเงินในกองทุนให้แจกจ่าย");

        for (uint256 i = 0; i < inheritors.length; i++) {
            if (inheritors[i].inheritorAddress != address(0)) { //แจกจ่ายเงินตามเปอร์เซ็นต์ให้กับผู้รับมรดก
                uint256 inheritorAmount = (totalBalance * inheritors[i].percentage) / 100; // คำนวณจำนวนเงินที่ต้องแจก  
                inheritors[i].inheritorAddress.transfer(inheritorAmount); //ทำการโอนเงินให้กับแต่ละคน
            }
        }
    }

    // 7. รักษาสัญญาให้คงอยู่ ("keep alive")
    function keepAlive() external onlyOwner { //เจ้าของสัญญาอัปเดตเวลา (lastAlive) ว่ายังมีชีวิต
        lastAlive = block.timestamp;
    }

    // 8. ตรวจสอบว่ามีการ keep alive
    function isAlive() external view returns (bool) { //ตรวจสอบช่วงเวลาที่ผ่านมา (นับจาก lastAlive) น้อยกว่า 365 วันหรือไม่
        return (block.timestamp - lastAlive) < 365 days;
    }
}