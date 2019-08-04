.. _threads_v2:

Threads
^^^^^^^

This section describes kernel services for creating, scheduling, and deleting
independently executable threads of instructions.

.. contents::
    :local:
    :depth: 1

.. _lifecycle_v2:

Lifecycle
#########

A :dfn:`thread` is a kernel object that is used for application processing that is too lengthy or too complex to be performed by an ISR.
   dfn: ' thread '是一个内核对象，用于处理太长或太复杂而不能由ISR执行的应用程序。

Concepts
********

Any number of threads can be defined by an application. Each thread is referenced by a :dfn:`thread id` that is assigned when the thread is spawned.

应用程序可以定义任意数量的线程。每个线程都由一个:dfn: ' thread id '引用，该id是在派生线程时分配的。


A thread has the following key properties:

* A **stack area**, which is a region of memory used for the thread's stack.
  The **size** of the stack area can be tailored to conform to the actual needs   of the thread's processing. Special macros exist to create and work with   stack memory regions.
一个**堆栈区域**，它是用于线程堆栈的内存区域。
堆栈区域的**size**可以根据线程处理的实际需要进行调整。存在用于创建和处理堆栈内存区域的特殊宏。

* A **thread control block** for private kernel bookkeeping of the thread's   metadata. This is an instance of type :c:type:`struct k_thread`.
一个**线程控制块**用于线程元数据的私有内核簿记。这是一个类型:c:type: ' struct k_thread '的实例。


* An **entry point function**, which is invoked when the thread is started.
  Up to 3 **argument values** can be passed to this function.
一个**入口点函数**，在线程启动时调用。最多3 **参数值**可以传递给这个函数。

* A **scheduling priority**, which instructs the kernel's scheduler how to   allocate CPU time to the thread. (See :ref:`scheduling_v2`.)
一个**调度优先级**，它指示内核的调度程序如何分配CPU时间给线程。(参见:裁判:“scheduling_v2”。)


* A set of **thread options**, which allow the thread to receive special   treatment by the kernel under specific circumstances.
  (See :ref:`thread_options_v2`.)
一组**线程选项**，允许线程在特定情况下接受内核的特殊处理。

* A **start delay**, which specifies how long the kernel should wait before   starting the thread.
一个**start delay**，它指定内核在启动线程之前应该等待多长时间。

* An **execution mode**, which can either be supervisor or user mode.
  By default, threads run in supervisor mode and allow access to   privileged CPU instructions, the entire memory address space, and
  peripherals. User mode threads have a reduced set of privileges.  This depends on the :option:`CONFIG_USERSPACE` option. See :ref:`usermode`.

.. _spawning_thread:

Thread Creation
===============

A thread must be created before it can be used. The kernel initializes the thread control block as well as one end of the stack portion. The remainder of the thread's stack is typically left uninitialized.
在使用线程之前，必须创建一个线程。内核初始化线程控制块和堆栈部分的一端。线程堆栈的其余部分通常未初始化。

Specifying a start delay of :c:macro:`K_NO_WAIT` instructs the kernel to start thread execution immediately. Alternatively, the kernel can be instructed to delay execution of the thread by specifying a timeout value -- for example, to allow device hardware used by the thread to become available.

指定:c:宏:' K_NO_WAIT '的启动延迟指示内核立即启动线程执行。或者，可以指示内核通过指定超时值来延迟线程的执行——例如，允许线程使用的设备硬件可用。

The kernel allows a delayed start to be canceled before the thread begins executing. A cancellation request has no effect if the thread has already started. A thread whose delayed start was successfully canceled must be re-spawned before it can be used.
内核允许在线程开始执行之前取消延迟的启动。如果线程已经启动，取消请求将不起作用。已成功取消延迟启动的线程必须重新生成才能使用。

Thread Termination 线程终止
==================

Once a thread is started it typically executes forever. However, a thread may synchronously end its execution by returning from its entry point function.
This is known as **termination**.
v一旦线程启动，它通常会永远执行。但是，线程可以通过从其入口点函数返回来同步结束其执行。
这就是所谓的**终止**。

A thread that terminates is responsible for releasing any shared resources it may own (such as mutexes and dynamically allocated memory) prior to returning, since the kernel does *not* reclaim them automatically.
终止的线程负责在返回之前释放它可能拥有的任何共享资源(例如互斥锁和动态分配的内存)，因为内核不会“自动”回收它们。

.. note::
    The kernel does not currently make any claims regarding an application's     ability to respawn a thread that terminates.
内核目前没有对应用程序重新生成终止线程的能力做出任何声明。
Thread Aborting
===============

A thread may asynchronously end its execution by **aborting**. The kernel automatically aborts a thread if the thread triggers a fatal error condition, such as dereferencing a null pointer.
线程可以通过**中止**以异步方式结束其执行。如果线程触发致命的错误条件，例如取消对空指针的引用，内核将自动中止线程。

A thread can also be aborted by another thread (or by itself) by calling :cpp:func:`k_thread_abort()`. However, it is typically preferable to signal a thread to terminate itself gracefully, rather than aborting it.
一个线程也可以通过调用:cpp:func: ' k_thread_abort() '被另一个线程中止(或由它自己中止)。然而，通常更可取的做法是发出信号让线程优雅地终止自己，而不是中止它。

As with thread termination, the kernel does not reclaim shared resources owned by an aborted thread.
与线程终止一样，内核不会回收中止线程拥有的共享资源。

.. note::
    The kernel does not currently make any claims regarding an application's ability to respawn a thread that aborts.
内核目前没有对应用程序重新生成中止的线程的能力做出任何声明。


Thread Suspension 线程挂起
=================

A thread can be prevented from executing for an indefinite period of time if it becomes **suspended**. The function :cpp:func:`k_thread_suspend()` can be used to suspend any thread, including the calling thread.
Suspending a thread that is already suspended has no additional effect.
如果线程变成**suspend **，则可以在不确定的时间内阻止它执行。函数:cpp:func: ' k_thread_suspend() '可用于挂起任何线程，包括调用线程。
挂起已经挂起的线程没有其他效果。

Once suspended, a thread cannot be scheduled until another thread calls :cpp:func:`k_thread_resume()` to remove the suspension.
一旦挂起，就不能调度线程，直到另一个线程调用:cpp:func: ' k_thread_resume() '来删除挂起。

.. note::
   A thread can prevent itself from executing for a specified period of time    using :cpp:func:`k_sleep()`. However, this is different from suspending  a thread since a sleeping thread becomes executable automatically when the    time limit is reached.
线程可以使用:cpp:func: ' k_sleep() '防止自己在指定的时间内执行。但是，这与挂起线程不同，因为休眠线程在达到时间限制时将自动执行。

.. _thread_options_v2:

Thread Options
==============

The kernel supports a small set of :dfn:`thread options` that allow a thread to receive special treatment under specific circumstances. The set of options associated with a thread are specified when the thread is spawned.
内核支持一组:dfn:“线程选项”，允许线程在特定环境下接受特殊处理。与线程关联的选项集在派生线程时指定。

A thread that does not require any thread option has an option value of zero.
A thread that requires a thread option specifies it by name, using the :literal:`|` character as a separator if multiple options are needed (i.e. combine options using the bitwise OR operator).
不需要任何线程选项的线程的选项值为零。
需要线程选项的线程通过名称指定它，如果需要多个选项(即使用位或操作符组合选项)，则使用:literal: ' | '字符作为分隔符。

The following thread options are supported.

:c:macro:`K_ESSENTIAL`
    This option tags the thread as an :dfn:`essential thread`. This instructs the kernel to treat the termination or aborting of the thread as a fatal system error.
    By default, the thread is not considered to be an essential thread.
这个选项将线程标记为:dfn: ' essential thread '。这指示内核将线程的终止或中止视为致命的系统错误。
默认情况下，线程不被认为是必要的线程。

:c:macro:`K_FP_REGS` and :c:macro:`K_SSE_REGS`
    These x86-specific options indicate that the thread uses the CPU's floating point registers and SSE registers, respectively. This instructs the kernel to take additional steps to save and restore the contents of these registers when scheduling the thread. (For more information see :ref:`float_v2`.)

    By default, the kernel does not attempt to save and restore the contents  of these registers when scheduling the thread.
这些x86特定的选项表明线程分别使用CPU的浮点寄存器和SSE寄存器。这指示内核在调度线程时采取其他步骤来保存和恢复这些寄存器的内容。(更多信息请参见:ref: ' float_v2 ')。
默认情况下，内核在调度线程时不会尝试保存和恢复这些寄存器的内容。


:c:macro:`K_USER`
    If :option:`CONFIG_USERSPACE` is enabled, this thread will be created in user mode and will have reduced privileges. See :ref:`usermode`. Otherwise this flag does nothing.
如果:option: ' CONFIG_USERSPACE '被启用，这个线程将在用户模式下创建，并且特权将减少。看到裁判:“usermode”。否则，此标志什么也不做。

:c:macro:`K_INHERIT_PERMS`
    If :option:`CONFIG_USERSPACE` is enabled, this thread will inherit all kernel object permissions that the parent thread had, except the parent thread object.  See :ref:`usermode`.
如果:option: ' CONFIG_USERSPACE '被启用，这个线程将继承父线程拥有的所有内核对象权限，除了父线程对象。看到裁判:“usermode”。

Implementation
**************

Spawning a Thread 产生一个线程
=================

A thread is spawned by defining its stack area and its thread control block, and then calling :cpp:func:`k_thread_create()`. The stack area must be defined using :c:macro:`K_THREAD_STACK_DEFINE` to ensure it is properly set up in memory.
通过定义其堆栈区域及其线程控制块，然后调用：cpp：func：`k_thread_create（）`来生成线程。
必须使用以下命令定义堆栈区域：c：macro：`K_THREAD_STACK_DEFINE`以确保它在内存中正确设置。

The thread spawning function returns its thread id, which can be used to reference the thread.

The following code spawns a thread that starts immediately.
线程生成函数返回其线程id，可用于引用线程。以下代码生成一个立即启动的线程。
.. code-block:: c

    #define MY_STACK_SIZE 500
    #define MY_PRIORITY 5

    extern void my_entry_point(void *, void *, void *);

    K_THREAD_STACK_DEFINE(my_stack_area, MY_STACK_SIZE);
    struct k_thread my_thread_data;

    k_tid_t my_tid = k_thread_create(&my_thread_data, my_stack_area,
                                     K_THREAD_STACK_SIZEOF(my_stack_area),
                                     my_entry_point,
                                     NULL, NULL, NULL,
                                     MY_PRIORITY, 0, K_NO_WAIT);

Alternatively, a thread can be spawned at compile time by calling
:c:macro:`K_THREAD_DEFINE`. Observe that the macro defines
the stack area, control block, and thread id variables automatically.

The following code has the same effect as the code segment above.

.. code-block:: c

    #define MY_STACK_SIZE 500
    #define MY_PRIORITY 5

    extern void my_entry_point(void *, void *, void *);

    K_THREAD_DEFINE(my_tid, MY_STACK_SIZE,
                    my_entry_point, NULL, NULL, NULL,
                    MY_PRIORITY, 0, K_NO_WAIT);

User Mode Constraints 用户模式约束
---------------------

This section only applies if :option:`CONFIG_USERSPACE` is enabled, and a user thread tries to create a new thread. The :c:func:`k_thread_create()` API is still used, but there are additional constraints which must be met or the calling thread will be terminated:
本节仅适用于：option：`CONFIG_USERSPACE`，并且用户线程尝试创建新线程。 ：c：func：`k_thread_create（）`API仍在使用，但还有其他约束必须满足或者调用线程将被终止：

* The calling thread must have permissions granted on both the child thread   and stack parameters; both are tracked by the kernel as kernel objects.

* The child thread and stack objects must be in an uninitialized state,  i.e. it is not currently running and the stack memory is unused.

* The stack size parameter passed in must be equal to or less than the   bounds of the stack object when it was declared.

* The :c:macro:`K_USER` option must be used, as user threads can only create  other user threads.

* The :c:macro:`K_ESSENTIAL` option must not be used, user threads may not be   considered essential threads.

* The priority of the child thread must be a valid priority value, and equal to  or lower than the parent thread.
*调用线程必须具有在子线程和堆栈参数上授予的权限; 两者都被内核跟踪为内核对象。
*子线程和堆栈对象必须处于未初始化状态，即它当前未运行且堆栈内存未使用。
*传入的堆栈大小参数必须等于或小于堆栈对象声明时的边界。
*：c：macro：必须使用`K_USER`选项，因为用户线程只能创建其他用户线程。
*：c：macro：不能使用`K_ESSENTIAL`选项，用户线程可能不被视为必需线程。
*子线程的优先级必须是有效的优先级值，并且等于或低于父线程。

Dropping Permissions
====================

If :option:`CONFIG_USERSPACE` is enabled, a thread running in supervisor mode may perform a one-way transition to user mode using the :cpp:func:`k_thread_user_mode_enter()` API. This is a one-way operation which will reset and zero the thread's stack memory. The thread will be marked as non-essential.

如果：选项：`CONFIG_USERSPACE`已启用，则以超级用户模式运行的线程可以使用：cpp：func：`k_thread_user_mode_enter（）`API执行到用户模式的单向转换。 这是一个单向操作，它将复位并将线程的堆栈内存归零。 该主题将被标记为非必要。
Terminating a Thread 终止线程
====================

A thread terminates itself by returning from its entry point function.

The following code illustrates the ways a thread can terminate.
线程通过从其入口点函数返回来终止自身。以下代码说明了线程可以终止的方式。


.. code-block:: c

    void my_entry_point(int unused1, int unused2, int unused3)
    {
        while (1) {
            ...
        if (<some condition>) {
            return; /* thread terminates from mid-entry point function */
        }
        ...
        }

        /* thread terminates at end of entry point function */
    }

If CONFIG_USERSPACE is enabled, aborting a thread will additionally mark the thread and stack objects as uninitialized so that they may be re-used.
如果启用了CONFIG_USERSPACE，则中止线程将另外将线程和堆栈对象标记为未初始化，以便可以重新使用它们。

Suggested Uses
**************

Use threads to handle processing that cannot be handled in an ISR.

Use separate threads to handle logically distinct processing operations that can execute in parallel.

使用线程处理无法在ISR中处理的处理。使用单独的线程来处理可以并行执行的逻辑上不同的处理操作。

.. _scheduling_v2:

Scheduling
##########

The kernel's priority-based scheduler allows an application's threads to share the CPU.
内核基于优先级的调度程序允许应用程序的线程共享CPU。

Concepts
********

The scheduler determines which thread is allowed to execute at any point in time; this thread is known as the **current thread**.

Whenever the scheduler changes the identity of the current thread, or when execution of the current thread is supplanted by an ISR,the kernel first saves the current thread's CPU register values. These register values get restored when the thread later resumes execution.
每当调度程序更改当前线程的标识，或者当ISR取代当前线程的执行时，内核首先保存当前线程的CPU寄存器值。 当线程稍后恢复执行时，将恢复这些寄存器值。

Thread States
=============

A thread that has no factors that prevent its execution is deemed to be **ready**, and is eligible to be selected as the current thread.

A thread that has one or more factors that prevent its execution is deemed to be **unready**, and cannot be selected as the current thread.

The following factors make a thread unready:

* The thread has not been started.
* The thread is waiting on for a kernel object to complete an operation. (For example, the thread is taking a semaphore that is unavailable.)
* The thread is waiting for a timeout to occur.
* The thread has been suspended.
* The thread has terminated or aborted.
没有阻止其执行的因素的线程被认为是**就绪**，并且有资格被选为当前线程。
具有一个或多个阻止其执行的因素的线程被视为**未准备**，并且不能被选为当前线程。
以下因素导致线程未准备好：
*线程尚未启动。
*线程正在等待内核对象完成操作。 （例如，线程正在获取不可用的信号量。）
*线程正在等待超时发生。
*线程已被暂停。
*线程已终止或中止。

Thread Priorities
=================

A thread's priority is an integer value, and can be either negative or non-negative.
Numerically lower priorities takes precedence over numerically higher values.
For example, the scheduler gives thread A of priority 4 *higher* priority over thread B of priority 7; likewise thread C of priority -2 has higher priority than both thread A and thread B.

线程的优先级是整数值，可以是负数也可以是非负数。
数值较低的优先级优先于数值较高的值。例如，调度程序给优先级高于优先级7的线程B优先级高4 *的线程A; 同样，优先级为-2的线程C具有比线程A和线程B更高的优先级。

The scheduler distinguishes between two classes of threads, based on each thread's priority.

* A :dfn:`cooperative thread` has a negative priority value.  Once it becomes the current thread, a cooperative thread remains   the current thread until it performs an action that makes it unready.

* A :dfn:`preemptible thread` has a non-negative priority value. Once it becomes the current thread, a preemptible thread may be supplanted   at any time if a cooperative thread, or a preemptible thread of higher   or equal priority, becomes ready.

A thread's initial priority value can be altered up or down after the thread has been started. Thus it possible for a preemptible thread to become a cooperative thread, and vice versa, by changing its priority.

The kernel supports a virtually unlimited number of thread priority levels. The configuration options :option:`CONFIG_NUM_COOP_PRIORITIES` and :option:`CONFIG_NUM_PREEMPT_PRIORITIES` specify the number of priority  levels for each class of thread, resulting the following usable priority ranges:

调度程序根据每个线程的优先级区分两类线程。
* A：dfn：`协作线程`具有负优先级值。一旦它成为当前线程，协作线程将保持当前线程，直到它执行使其未准备的操作。
* A：dfn：`preemptible thread`具有非负优先级值。一旦它成为当前线程，如果协作线程或优先级更高或相同的可抢占线程准备就绪，则可以随时取代可抢占线程。

线程启动后，可以向上或向下更改线程的初始优先级值。因此，通过改变其优先级，可抢占线程可以成为协作线程，反之亦然。内核支持几乎无限数量的线程优先级。
配置选项：选项：`CONFIG_NUM_COOP_PRIORITIES`和：选项：`CONFIG_NUM_PREEMPT_PRIORITIES`指定每个线程类的优先级数，从而产生以下可用优先级范围：

* cooperative threads: (-:option:`CONFIG_NUM_COOP_PRIORITIES`) to -1
* preemptive threads: 0 to (:option:`CONFIG_NUM_PREEMPT_PRIORITIES` - 1)

For example, configuring 5 cooperative priorities and 10 preemptive priorities
results in the ranges -5 to -1 and 0 to 9, respectively.

Scheduling Algorithm
====================

The kernel's scheduler selects the highest priority ready thread to be the current thread. When multiple ready threads of the same priority exist, the scheduler chooses the one that has been waiting longest.

.. note::
    Execution of ISRs takes precedence over thread execution, so the execution of the current thread may be supplanted by an ISR at any time unless interrupts have been masked. This applies to both cooperative threads and preemptive threads.

内核的调度程序选择优先级最高的就绪线程作为当前线程。 当存在多个具有相同优先级的就绪线程时，调度程序选择等待时间最长的线程。..
注意：：
ISR的执行优先于线程执行，因此当前线程的执行可以随时被ISR取代，除非中断被屏蔽。 这适用于协作线程和抢占线程。

Cooperative Time Slicing  合作时间切片
========================

Once a cooperative thread becomes the current thread, it remains the current thread until it performs an action that makes it unready.
Consequently, if a cooperative thread performs lengthy computations,it may cause an unacceptable delay in the scheduling of other threads,including those of higher priority and equal priority.
一旦合作线程成为当前线程，它将保持当前线程，直到执行使其无法读取的操作为止。
因此，如果一个合作线程执行长时间的计算，它可能会导致其他线程（包括优先级更高和优先级相同的线程）的调度出现不可接受的延迟。

To overcome such problems, a cooperative thread can voluntarily relinquish the CPU from time to time to permit other threads to execute.
A thread can relinquish the CPU in two ways:

为了克服这些问题，一个合作线程可以自动地不时地放弃CPU以允许其他线程执行。
线程可以通过两种方式放弃CPU：

* Calling :cpp:func:`k_yield()` puts the thread at the back of the scheduler's prioritized list of ready threads, and then invokes the scheduler.
  All ready threads whose priority is higher or equal to that of the yielding thread are then allowed to execute before the yielding thread is rescheduled. If no such ready threads exist, the scheduler immediately reschedules the yielding thread without context switching.

调用：cpp:func:`k_yield（）`会将线程放在调度程序的就绪线程优先列表的后面，然后调用调度程序。
然后允许优先级高于或等于生成线程优先级的所有就绪线程在重新计划生成线程之前执行。如果不存在这样的准备好的线程，调度程序会立即重新调度生成的线程，而不进行上下文切换。

* Calling :cpp:func:`k_sleep()` makes the thread unready for a specified time period. Ready threads of *all* priorities are then allowed to execute; however, there is no guarantee that threads whose priority is lower than that of the sleeping thread will actually be scheduled before the sleeping thread becomes ready once again.

调用：cpp:func:`k_sleep（）`会使线程在指定的时间段内未读。然后允许执行*所有*优先级的就绪线程；但是，不能保证优先级低于休眠线程的线程将在休眠线程再次准备就绪之前被调度。

Preemptive Time Slicing 抢占时间切片
=======================

Once a preemptive thread becomes the current thread, it remains the current thread until a higher priority thread becomes ready, or until the thread performs an action that makes it unready. Consequently, if a preemptive thread performs lengthy computations,it may cause an unacceptable delay in the scheduling of other threads, including those of equal priority.



To overcome such problems, a preemptive thread can perform cooperative time slicing (as described above), or the scheduler's time slicing capability can be used to allow other threads of the same priority to execute.

The scheduler divides time into a series of **time slices**, where slices are measured in system clock ticks. The time slice size is configurable,but this size can be changed while the application is running.

At the end of every time slice, the scheduler checks to see if the current thread is preemptible and, if so, implicitly invokes :cpp:func:`k_yield()` on behalf of the thread. This gives other ready threads of the same priority the opportunity to execute before the current thread is scheduled again. If no threads of equal priority are ready, the current thread remains the current thread.

Threads with a priority higher than specified limit are exempt from preemptive time slicing, and are never preempted by a thread of equal priority. This allows an application to use preemptive time slicing only when dealing with lower priority threads that are less time-sensitive.


一旦抢占线程成为当前线程，它将保持当前线程，直到更高优先级的线程准备就绪，或者直到线程执行使其未读的操作。因此，如果抢占线程执行较长的计算，可能会导致其他线程（包括具有同等优先级的线程）的调度延迟，这是不可接受的。
为了克服这些问题，抢占线程可以执行协同时间切片（如上所述），或者调度程序的时间切片功能可以用于允许其他具有相同优先级的线程执行。
调度程序将时间划分为一系列**时间片**，在这些时间片中，以系统时钟节拍测量时间片。时间片大小是可配置的，但在应用程序运行时可以更改该大小。
在每个时间片的末尾，调度程序检查当前线程是否可抢占，如果可以，则代表线程隐式调用：cpp:func:`k_yield（）'。这使具有相同优先级的其他就绪线程有机会在再次调度当前线程之前执行。如果没有同等优先级的线程准备就绪，则当前线程将保留当前线程。
优先级高于指定限制的线程不受抢占时间切片的限制，并且永远不会被同等优先级的线程抢占。这允许应用程序仅在处理时间敏感度较低的低优先级线程时才使用抢占式时间切片。


.. note::
   The kernel's time slicing algorithm does *not* ensure that a set    of equal-priority threads receive an equitable amount of CPU time,   since it does not measure the amount of time a thread actually gets to   execute. For example, a thread may become the current thread just before    the end of a time slice and then immediately have to yield the CPU.   However, the algorithm *does* ensure that a thread never executes   for longer than a single time slice without being required to yield.
内核的时间切片算法*不能*确保一组等优先级的线程获得相当的CPU时间，因为它不度量线程实际执行的时间。例如，一个线程可能在一个时间片结束之前成为当前线程，然后必须立即生成CPU。
然而，算法*确实*确保线程执行的时间不会超过一个时间片，而不需要生成。

Scheduler Locking
=================

A preemptible thread that does not wish to be preempted while performing a critical operation can instruct the scheduler to temporarily treat it as a cooperative thread by calling :cpp:func:`k_sched_lock()`. This prevents other threads from interfering while the critical operation is being performed.

Once the critical operation is complete the preemptible thread must call :cpp:func:`k_sched_unlock()` to restore its normal, preemptible status.

If a thread calls :cpp:func:`k_sched_lock()` and subsequently performs an action that makes it unready, the scheduler will switch the locking thread out and allow other threads to execute. When the locking thread again becomes the current thread, its non-preemptible status is maintained.

.. note::
    Locking out the scheduler is a more efficient way for a preemptible thread to inhibit preemption than changing its priority level to a negative value.



执行关键操作时不希望被抢占的可抢占线程可以通过调用：cpp:func:`k_sched_lock（）`，指示计划程序将其临时视为合作线程。这可以防止其他线程在执行关键操作时干扰。
关键操作完成后，可抢占线程必须调用：cpp:func:`k_sched_unlock（）`以恢复其正常的可抢占状态。
如果一个线程调用：cpp:func:`k_sched_lock（）`并随后执行一个使其无法读取的操作，调度程序将切换锁定线程并允许其他线程执行。当锁定线程再次成为当前线程时，将保持其不可抢占状态。
…注：
锁定调度程序对于可抢占线程来说，比将其优先级更改为负值更有效地抑制抢占。

.. _metairq_priorities:
Meta-IRQ Priorities
===================

When enabled (see :option:`CONFIG_NUM_METAIRQ_PRIORITIES`), there is a special subclass of cooperative priorities at the highest (numerically lowest) end of the priority space: meta-IRQ threads.  These are scheduled  according to their normal priority, but also have the special ability to preempt all other threads (and other meta-irq threads) at lower
priorities, even if those threads are cooperative and/or have taken a scheduler lock.

This behavior makes the act of unblocking a meta-IRQ thread (by any means, e.g. creating it, calling k_sem_give(), etc.) into the equivalent of a synchronous system call when done by a lower priority thread, or an ARM-like "pended IRQ" when done from true interrupt context.  The intent is that this feature will be used to implement interrupt "bottom half" processing and/or "tasklet" features in driver subsystems.  The thread, once woken, will be guaranteed to run before the current CPU returns into application code.

Unlike similar features in other OSes, meta-IRQ threads are true threads and run on their own stack (which much be allocated normally), not the per-CPU interrupt stack.  Design work to enable the use of the IRQ stack on supported architectures is pending.

Note that because this breaks the promise made to cooperative threads by the Zephyr API (namely that the OS won't schedule other thread until the current thread deliberately blocks), it should be used only with great care from application code.  These are not simply very high priority threads and should not be used as such.


启用时（请参阅：选项：`CONFIG_NUM_METAIRQ_PRIORITIES`），在优先级空间的最高（数字最低）端有一个特殊的协作优先级子类：meta-IRQ线程。这些是根据它们的正常优先级进行安排的，但也具有在较低级别抢占所有其他线程（和其他meta-irq线程）的特殊能力优先级，即使这些线程是合作的和/或已经采取了调度程序锁定。

这种行为使得在由较低优先级的线程或类似ARM的线程完成时，取消阻止元IRQ线程（通过任何方式，例如创建它，调用k_sem_give（）等）的行为等同于同步系统调用。从真正的中断上下文完成时“挂起IRQ”。目的是该功能将用于在驱动子系统中实现中断“下半部分”处理和/或“tasklet”功能。一旦被唤醒，该线程将保证在当前CPU返回应用程序代码之前运行。

与其他操作系统中的类似功能不同，元IRQ线程是真正的线程并在它们自己的堆栈上运行（通常分配很多），而不是每CPU中断堆栈。支持在支持的体系结构上使用IRQ堆栈的设计工作正在进行中。

请注意，因为这违反了Zephyr API对协作线程的承诺（即操作系统不会在当前线程故意阻塞之前调度其他线程），所以应该非常谨慎地使用应用程序代码。这些不仅仅是非常高优先级的线程，不应该这样使用。

.. _thread_sleeping:

Thread Sleeping
===============

A thread can call :cpp:func:`k_sleep()` to delay its processing for a specified time period. During the time the thread is sleeping the CPU is relinquished to allow other ready threads to execute.
Once the specified delay has elapsed the thread becomes ready and is eligible to be scheduled once again.

A sleeping thread can be woken up prematurely by another thread using :cpp:func:`k_wakeup()`. This technique can sometimes be used to permit the secondary thread to signal the sleeping thread that something has occurred *without* requiring the threads to define a kernel synchronization object, such as a semaphore. Waking up a thread that is not sleeping is allowed, but has no effect.

线程可以调用：cpp：func：`k_sleep（）`来延迟其处理指定的时间段。 在线程休眠期间，CPU被放弃以允许其他就绪线程执行。一旦指定的延迟时间结束，线程就会准备就绪，并且有资格再次安排。

睡眠线程可以被另一个线程过早地唤醒，使用：cpp：func：`k_wakeup（）`。 此技术有时可用于允许辅助线程向睡眠线程发出已发生某事的信号*，而不要求线程定义内核同步对象，例如信号量。 允许唤醒未休眠的线程，但没有效果。
.. _busy_waiting:

Busy Waiting
============

A thread can call :cpp:func:`k_busy_wait()` to perform a ``busy wait`` that delays its processing for a specified time period *without* relinquishing the CPU to another ready thread.

A busy wait is typically used instead of thread sleeping  when the required delay is too short to warrant having the scheduler context switch from the current thread to another thread and then back again.

Suggested Uses
**************

Use cooperative threads for device drivers and other performance-critical work.

Use cooperative threads to implement mutually exclusion without the need for a kernel object, such as a mutex.

Use preemptive threads to give priority to time-sensitive processing over less time-sensitive processing.

忙着等待
============
一个线程可以调用：cpp：func：`k_busy_wait（）`来执行一个``busy wait``，它会延迟处理指定的时间段*而不会将CPU放到另一个就绪线程上。
当所需的延迟太短以至于无法保证调度程序上下文从当前线程切换到另一个线程然后再返回时，通常使用忙等待而不是线程休眠。
建议用途
**************
将协作线程用于设备驱动程序和其他性能关键的工作。使用协作线程实现互斥，而无需内核对象，例如互斥锁。使用抢先线程优先考虑时间敏感的处理，而不是时间敏感的处理。

.. _custom_data_v2:

Custom Data
###########

A thread's :dfn:`custom data` is a 32-bit, thread-specific value that may be used by an application for any purpose.

Concepts
********

Every thread has a 32-bit custom data area.
The custom data is accessible only by the thread itself, and may be used by the application for any purpose it chooses.
The default custom data for a thread is zero.

.. note::
   Custom data support is not available to ISRs because they operate within a single shared kernel interrupt handling context.

自定义数据
##########
#线程：
dfn：`custom data`是一个32位特定于线程的值，应用程序可以将其用于任何目的。
概念
********
每个线程都有一个32位自定义数据区。自定义数据只能由线程本身访问，并且可以由应用程序用于它选择的任何目的。线程的默认自定义数据为零。.. 
注意：：    
ISR无法使用自定义数据支持，因为它们在单个共享内核中断处理上下文中运行。

Implementation
**************

Using Custom Data
=================

By default, thread custom data support is disabled. The configuration option
:option:`CONFIG_THREAD_CUSTOM_DATA` can be used to enable support.

The :cpp:func:`k_thread_custom_data_set()` and
:cpp:func:`k_thread_custom_data_get()` functions are used to write and read
a thread's custom data, respectively. A thread can only access its own
custom data, and not that of another thread.

The following code uses the custom data feature to record the number of times
each thread calls a specific routine.

.. note::
    Obviously, only a single routine can use this technique,
    since it monopolizes the use of the custom data feature.

.. code-block:: c

    int call_tracking_routine(void)
    {
        u32_t call_count;

        if (k_is_in_isr()) {
        /* ignore any call made by an ISR */
        } else {
            call_count = (u32_t)k_thread_custom_data_get();
            call_count++;
            k_thread_custom_data_set((void *)call_count);
    }

        /* do rest of routine's processing */
        ...
    }

Suggested Uses
**************

Use thread custom data to allow a routine to access thread-specific information,
by using the custom data as a pointer to a data structure owned by the thread.

.. _system_threads_v2:

System Threads
##############

A :dfn:`system thread` is a thread that the kernel spawns automatically
during system initialization.

Concepts
********

The kernel spawns the following system threads.

**Main thread**
    This thread performs kernel initialization, then calls the application's
    :cpp:func:`main()` function (if one is defined).

    By default, the main thread uses the highest configured preemptible thread
    priority (i.e. 0). If the kernel is not configured to support preemptible
    threads, the main thread uses the lowest configured cooperative thread
    priority (i.e. -1).

    The main thread is an essential thread while it is performing kernel
    initialization or executing the application's :cpp:func:`main()` function;
    this means a fatal system error is raised if the thread aborts. If
    :cpp:func:`main()` is not defined, or if it executes and then does a normal
    return, the main thread terminates normally and no error is raised.

**Idle thread**
    This thread executes when there is no other work for the system to do.
    If possible, the idle thread activates the board's power management support
    to save power; otherwise, the idle thread simply performs a "do nothing"
    loop. The idle thread remains in existence as long as the system is running
    and never terminates.

    The idle thread always uses the lowest configured thread priority.
    If this makes it a cooperative thread, the idle thread repeatedly
    yields the CPU to allow the application's other threads to run when
    they need to.

    The idle thread is an essential thread, which means a fatal system error
    is raised if the thread aborts.

Additional system threads may also be spawned, depending on the kernel
and board configuration options specified by the application. For example,
enabling the system workqueue spawns a system thread
that services the work items submitted to it. (See :ref:`workqueues_v2`.)

Implementation
**************

Writing a main() function
=========================

An application-supplied :cpp:func:`main()` function begins executing once
kernel initialization is complete. The kernel does not pass any arguments
to the function.

The following code outlines a trivial :cpp:func:`main()` function.
The function used by a real application can be as complex as needed.

.. code-block:: c

    void main(void)
    {
        /* initialize a semaphore */
    ...

    /* register an ISR that gives the semaphore */
    ...

    /* monitor the semaphore forever */
    while (1) {
        /* wait for the semaphore to be given by the ISR */
        ...
        /* do whatever processing is now needed */
        ...
    }
    }

Suggested Uses
**************

Use the main thread to perform thread-based processing in an application
that only requires a single thread, rather than defining an additional
application-specific thread.

.. _workqueues_v2:

Workqueue Threads
#################

A :dfn:`workqueue` is a kernel object that uses a dedicated thread to process
work items in a first in, first out manner. Each work item is processed by
calling the function specified by the work item. A workqueue is typically
used by an ISR or a high-priority thread to offload non-urgent processing
to a lower-priority thread so it does not impact time-sensitive processing.

Concepts
********

Any number of workqueues can be defined. Each workqueue is referenced by its
memory address.

A workqueue has the following key properties:

* A **queue** of work items that have been added, but not yet processed.

* A **thread** that processes the work items in the queue. The priority of the
  thread is configurable, allowing it to be either cooperative or preemptive
  as required.

A workqueue must be initialized before it can be used. This sets its queue
to empty and spawns the workqueue's thread.

Work Item Lifecycle
===================

Any number of **work items** can be defined. Each work item is referenced
by its memory address.

A work item has the following key properties:

* A **handler function**, which is the function executed by the workqueue's
  thread when the work item is processed. This function accepts a single
  argument, which is the address of the work item itself.

* A **pending flag**, which is used by the kernel to signify that the
  work item is currently a member of a workqueue's queue.

* A **queue link**, which is used by the kernel to link a pending work
  item to the next pending work item in a workqueue's queue.

A work item must be initialized before it can be used. This records the work
item's handler function and marks it as not pending.

A work item may be **submitted** to a workqueue by an ISR or a thread.
Submitting a work item appends the work item to the workqueue's queue.
Once the workqueue's thread has processed all of the preceding work items
in its queue the thread will remove a pending work item from its queue and
invoke the work item's handler function. Depending on the scheduling priority
of the workqueue's thread, and the work required by other items in the queue,
a pending work item may be processed quickly or it may remain in the queue
for an extended period of time.

A handler function can utilize any kernel API available to threads. However,
operations that are potentially blocking (e.g. taking a semaphore) must be
used with care, since the workqueue cannot process subsequent work items in
its queue until the handler function finishes executing.

The single argument that is passed to a handler function can be ignored if
it is not required. If the handler function requires additional information
about the work it is to perform, the work item can be embedded in a larger
data structure. The handler function can then use the argument value to compute
the address of the enclosing data structure, and thereby obtain access to the
additional information it needs.

A work item is typically initialized once and then submitted to a specific
workqueue whenever work needs to be performed. If an ISR or a thread attempts
to submit a work item that is already pending, the work item is not affected;
the work item remains in its current place in the workqueue's queue, and
the work is only performed once.

A handler function is permitted to re-submit its work item argument
to the workqueue, since the work item is no longer pending at that time.
This allows the handler to execute work in stages, without unduly delaying
the processing of other work items in the workqueue's queue.

.. important::
    A pending work item *must not* be altered until the item has been processed
    by the workqueue thread. This means a work item must not be re-initialized
    while it is pending. Furthermore, any additional information the work item's
    handler function needs to perform its work must not be altered until
    the handler function has finished executing.

Delayed Work
============

An ISR or a thread may need to schedule a work item that is to be processed
only after a specified period of time, rather than immediately. This can be
done by submitting a **delayed work item** to a workqueue, rather than a
standard work item.

A delayed work item is a standard work item that has the following added
properties:

* A **delay** specifying the time interval to wait before the work item
  is actually submitted to a workqueue's queue.

* A **workqueue indicator** that identifies the workqueue the work item
  is to be submitted to.

A delayed work item is initialized and submitted to a workqueue in a similar
manner to a standard work item, although different kernel APIs are used.
When the submit request is made the kernel initiates a timeout mechanism
that is triggered after the specified delay has elapsed. Once the timeout
occurs the kernel submits the delayed work item to the specified workqueue,
where it remains pending until it is processed in the standard manner.

An ISR or a thread may **cancel** a delayed work item it has submitted,
providing the work item's timeout is still counting down. The work item's
timeout is aborted and the specified work is not performed.

Attempting to cancel a delayed work item once its timeout has expired has
no effect on the work item; the work item remains pending in the workqueue's
queue, unless the work item has already been removed and processed by the
workqueue's thread. Consequently, once a work item's timeout has expired
the work item is always processed by the workqueue and cannot be canceled.

System Workqueue
================

The kernel defines a workqueue known as the *system workqueue*, which is
available to any application or kernel code that requires workqueue support.
The system workqueue is optional, and only exists if the application makes
use of it.

.. important::
    Additional workqueues should only be defined when it is not possible
    to submit new work items to the system workqueue, since each new workqueue
    incurs a significant cost in memory footprint. A new workqueue can be
    justified if it is not possible for its work items to co-exist with
    existing system workqueue work items without an unacceptable impact;
    for example, if the new work items perform blocking operations that
    would delay other system workqueue processing to an unacceptable degree.

Implementation
**************

Defining a Workqueue
====================

A workqueue is defined using a variable of type :c:type:`struct k_work_q`.
The workqueue is initialized by defining the stack area used by its thread
and then calling :cpp:func:`k_work_q_start()`. The stack area must be defined
using :c:macro:`K_THREAD_STACK_DEFINE` to ensure it is properly set up in
memory.

The following code defines and initializes a workqueue.

.. code-block:: c

    #define MY_STACK_SIZE 512
    #define MY_PRIORITY 5

    K_THREAD_STACK_DEFINE(my_stack_area, MY_STACK_SIZE);

    struct k_work_q my_work_q;

    k_work_q_start(&my_work_q, my_stack_area,
                   K_THREAD_STACK_SIZEOF(my_stack_area), MY_PRIORITY);

Submitting a Work Item
======================

A work item is defined using a variable of type :c:type:`struct k_work`.
It must then be initialized by calling :cpp:func:`k_work_init()`.

An initialized work item can be submitted to the system workqueue by
calling :cpp:func:`k_work_submit()`, or to a specified workqueue by
calling :cpp:func:`k_work_submit_to_queue()`.

The following code demonstrates how an ISR can offload the printing
of error messages to the system workqueue. Note that if the ISR attempts
to resubmit the work item while it is still pending, the work item is left
unchanged and the associated error message will not be printed.

.. code-block:: c

    struct device_info {
        struct k_work work;
        char name[16]
    } my_device;

    void my_isr(void *arg)
    {
        ...
        if (error detected) {
            k_work_submit(&my_device.work);
    }
    ...
    }

    void print_error(struct k_work *item)
    {
        struct device_info *the_device =
            CONTAINER_OF(item, struct device_info, work);
        printk("Got error on device %s\n", the_device->name);
    }

    /* initialize name info for a device */
    strcpy(my_device.name, "FOO_dev");

    /* initialize work item for printing device's error messages */
    k_work_init(&my_device.work, print_error);

    /* install my_isr() as interrupt handler for the device (not shown) */
    ...

Submitting a Delayed Work Item
==============================

A delayed work item is defined using a variable of type
:c:type:`struct k_delayed_work`. It must then be initialized by calling
:cpp:func:`k_delayed_work_init()`.

An initialized delayed work item can be submitted to the system workqueue by
calling :cpp:func:`k_delayed_work_submit()`, or to a specified workqueue by
calling :cpp:func:`k_delayed_work_submit_to_queue()`. A delayed work item
that has been submitted but not yet consumed by its workqueue can be canceled
by calling :cpp:func:`k_delayed_work_cancel()`.

Suggested Uses
**************

Use the system workqueue to defer complex interrupt-related processing
from an ISR to a cooperative thread. This allows the interrupt-related
processing to be done promptly without compromising the system's ability
to respond to subsequent interrupts, and does not require the application
to define an additional thread to do the processing.

Configuration Options
#####################

Related configuration options:

* :option:`CONFIG_SYSTEM_WORKQUEUE_STACK_SIZE`
* :option:`CONFIG_SYSTEM_WORKQUEUE_PRIORITY`
* :option:`CONFIG_MAIN_THREAD_PRIORITY`
* :option:`CONFIG_MAIN_STACK_SIZE`
* :option:`CONFIG_IDLE_STACK_SIZE`
* :option:`CONFIG_THREAD_CUSTOM_DATA`
* :option:`CONFIG_NUM_COOP_PRIORITIES`
* :option:`CONFIG_NUM_PREEMPT_PRIORITIES`
* :option:`CONFIG_TIMESLICING`
* :option:`CONFIG_TIMESLICE_SIZE`
* :option:`CONFIG_TIMESLICE_PRIORITY`
* :option:`CONFIG_USERSPACE`



API Reference
#############

.. doxygengroup:: thread_apis
   :project: Zephyr
